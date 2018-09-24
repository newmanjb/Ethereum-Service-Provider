pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ServiceProvider.sol";
import "../contracts/FilmRentalService.sol";

/**
 * Unit tests that test the paid subscription functionality in the ServiceProvider contract
 * with the user only subscribing to one service.
 */
contract SubscribeToOneServiceTest {

    ServiceProvider private serviceProvider;
    string constant private film = "www.getMyFilm.com/logan";
    string private filmRentalServiceName;

    uint public initialBalance = 10 ether;

    function beforeEachTest() public {
        address a = DeployedAddresses.FilmRentalService();
        filmRentalServiceName = Service(a).getServiceName();
        address[] memory addresses = new address[](1);
        addresses[0] =a;
        serviceProvider = new ServiceProvider(addresses);
    }

    /**
     * 1: Subscribe user for one day and check that they are subscribed and can use the service.
     * 2: Move the current day of the service on by one.
     * 3: Check that the user's subscription has expired and that
     *    they are no longer able to use the service.
     * 4: Repeat step 1 but subscribe for 2 days.
     * 5: Repeat step 2 and check that they can still use the service.
     * 6: Repeat step 2 again.  Now they should be expired.
     *
     * Balances are also checked in this test after every subscription.
     */
    function testSubscription_1() public {
        address spAddress = address(serviceProvider);
        address thisAddress = address(this);

        uint initialBalanceForSubscriber = thisAddress.balance;
        uint initialBalanceForServiceProvider = spAddress.balance;

        uint value = serviceProvider.feePerDayInWei();
        uint numDaysPaidFor = serviceProvider.subscribeFor.value(value)(filmRentalServiceName);

        Assert.equal(thisAddress.balance, initialBalanceForSubscriber - value, "Incorrect balance for subscriber");
        Assert.equal(spAddress.balance, initialBalanceForServiceProvider + value, "Incorrect balance for serviceProvider");

        Assert.equal(numDaysPaidFor, 1, "Incorrect num days subscribed for");
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==0, true, "User not subscribed");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),film,"Wrong film");

        serviceProvider.setDay(serviceProvider.getDay() + 1);

        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==1, true, "User's subscription should have expired");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),serviceProvider.notsubscribed(),"Service doesn't provide correct message to unsubscribed user");

        numDaysPaidFor = serviceProvider.subscribeFor.value(value * 2)(filmRentalServiceName);

        Assert.equal(thisAddress.balance, initialBalanceForSubscriber - (3*value), "Incorrect balance for subscriber");
        Assert.equal(spAddress.balance, initialBalanceForServiceProvider + (3*value), "Incorrect balance for serviceProvider");

        Assert.equal(numDaysPaidFor, 2, "Incorrect num days subscribed to");
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==0, true, "User not subscribed");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),film,"Wrong film");

        serviceProvider.setDay(serviceProvider.getDay() + 1);

        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==0, true, "User not subscribed");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),film,"Wrong film");

        serviceProvider.setDay(serviceProvider.getDay() + 1);

        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==1, true, "User's subscription should have expired");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),serviceProvider.notsubscribed(),"Service doesn't provide correct message to unsubscribed user");
    }
}
