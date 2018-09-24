pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ServiceProvider.sol";
import "../contracts/FilmRentalService.sol";

/**
 * Unit tests that test the paid subscription functionality in the ServiceProvider contract
 * with the user subscribing to two services.
 */
contract SubscribeToTwoServicesTest {

    ServiceProvider private serviceProvider;
    string constant private film = "www.getMyFilm.com/logan";
    string constant private book = "www.ebooks.com/fiftyShadesBarrelScraping_whatChristianGreysHamsterSaw";
    string private filmRentalServiceName;
    string private eBookServiceName;
    address private filmServiceAddress;
    address private eBookServiceAddress;

    uint public initialBalance = 10 ether;


    function beforeAll() public {
        filmServiceAddress = DeployedAddresses.FilmRentalService();
        filmRentalServiceName = Service(filmServiceAddress).getServiceName();
        eBookServiceAddress = DeployedAddresses.EBookDownloadService();
        eBookServiceName = Service(eBookServiceAddress).getServiceName();
    }


    function beforeEachTest() public {
        address[] memory addresses = new address[](2);
        addresses[0] = filmServiceAddress;
        addresses[1] = eBookServiceAddress;
        serviceProvider = new ServiceProvider(addresses);
    }

    /**
     * See comments in code
     */
    function testSubscription_1() public {

        address spAddress = address(serviceProvider);
        address thisAddress = address(this);

        //Save these values and use them to calculate what the balances of the sender
        //and subsriber should be each time anything has been spent
        uint initialBalanceForSubscriber = thisAddress.balance;
        uint initialBalanceForServiceProvider = spAddress.balance;

        //Subscribe for one day to the film rental service
        uint value = serviceProvider.feePerDayInWei();
        uint numDaysPaidFor = serviceProvider.subscribeFor.value(value)(filmRentalServiceName);

        //Make sure the values are correct
        Assert.equal(thisAddress.balance, initialBalanceForSubscriber - value, "Incorrect balance for subscriber");
        Assert.equal(spAddress.balance, initialBalanceForServiceProvider + value, "Incorrect balance for serviceProvider");

        //Make sure we're subscribed and can use the service
        Assert.equal(numDaysPaidFor, 1, "Incorrect num days subscribed for");
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==0, true, "User not subscribed");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),film,"Wrong film");

        //Move one by one day
        serviceProvider.setDay(serviceProvider.getDay() + 1);

        //Subscribe to the ebook service
        numDaysPaidFor = serviceProvider.subscribeFor.value(value)(eBookServiceName);
        //Check the values
        Assert.equal(thisAddress.balance, initialBalanceForSubscriber - (value*2), "Incorrect balance for subscriber");
        Assert.equal(spAddress.balance, initialBalanceForServiceProvider + (value*2), "Incorrect balance for serviceProvider");

        //Make sure we're subscribed and can use the service
        Assert.equal(numDaysPaidFor, 1, "Incorrect num days subscribed for");
        Assert.equal(serviceProvider.getSubscriptionStatus(eBookServiceName)==0, true, "User not subscribed");
        Assert.equal(serviceProvider.callService(eBookServiceName),book,"Wrong book");

        //Make sure that our 1-day subscription to the film rental service from yesterday has expired and that we can't use the service any more
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==1, true, "User's subscription should have expired");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),serviceProvider.notsubscribed(),"Service doesn't provide correct message to unsubscribed user");

        //Subscribe to the film rental service for 2 days
        numDaysPaidFor = serviceProvider.subscribeFor.value(value * 2)(filmRentalServiceName);

        //Check the values and make sure that the film rental service is active again and that we can use it
        Assert.equal(thisAddress.balance, initialBalanceForSubscriber - (4*value), "Incorrect balance for subscriber");
        Assert.equal(spAddress.balance, initialBalanceForServiceProvider + (4*value), "Incorrect balance for serviceProvider");
        Assert.equal(numDaysPaidFor, 2, "Incorrect num days subscribed to");
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==0, true, "User not subscribed");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),film,"Wrong film");

        //Move on by one day
        serviceProvider.setDay(serviceProvider.getDay() + 1);

        //The 2-day film rental service subscription should still be active
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==0, true, "User not subscribed");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),film,"Wrong film");

        //The 1-day ebook service subscription from yesterday should not be active any more
        Assert.equal(serviceProvider.getSubscriptionStatus(eBookServiceName)==1, true, "User's subscription to ebook service should have expired");
        Assert.equal(serviceProvider.callService(eBookServiceName),serviceProvider.notsubscribed(),"Service doesn't provide correct message to unsubscribed user");

        //Subsribe to the ebook service for 2 days
        numDaysPaidFor = serviceProvider.subscribeFor.value(value * 2)(eBookServiceName);
        //Check the values
        Assert.equal(thisAddress.balance, initialBalanceForSubscriber - (6*value), "Incorrect balance for subscriber");
        Assert.equal(spAddress.balance, initialBalanceForServiceProvider + (6*value), "Incorrect balance for serviceProvider");

        //Move on by a day
        serviceProvider.setDay(serviceProvider.getDay() + 1);

        //Check that the 2-day film rental service subscription has expired but that the 2-day ebook service subscription is still active
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==1, true, "User's subscription to film service should have expired");
        Assert.equal(serviceProvider.callService(filmRentalServiceName),serviceProvider.notsubscribed(),"Service doesn't provide correct message to unsubscribed user");

        Assert.equal(serviceProvider.getSubscriptionStatus(eBookServiceName)==0, true, "User's subscription to ebook service should still be active");
        Assert.equal(serviceProvider.callService(eBookServiceName),book,"Wrong book");
    }
}
