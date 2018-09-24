pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ServiceProvider.sol";
import "../contracts/FilmRentalService.sol";
import "../contracts/EBookDownloadService.sol";

/**
 * Unit tests for the trial subscription functionality in the ServiceProvider contract
 * with 2 services being subscribed to.
 */
contract SubscribeToTwoServicesTrialTest1 {

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

    function testOwner() public {
        Assert.equal(serviceProvider.owner(), this, "Owner should be the deployer");
    }

    //Cycle a user through the different stages of subscription i.e.
    //Not subscribed
    //subscribed
    //expired
    //and make sure that the getSubscriptionStatus function returns the correct subscription status each time
    function testGetSubscriptionStatus() public {

        //Subscribe to one service immediately and the other a day later so as the services expire at different times

        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==2,true,"Service thinks a non-subscribed user has subscribed");
        serviceProvider.subscribeToTrial(filmRentalServiceName);
	      Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==0,true,"Service thinks a subscribed user has not subscribed");

        Assert.equal(serviceProvider.getSubscriptionStatus(eBookServiceName)==2,true,"Service thinks a non-subscribed user has subscribed");

        serviceProvider.setDay(2);

        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==1,true,"Service is not picking up the fact that a user has expired");
        serviceProvider.subscribeToTrial(eBookServiceName);
        Assert.equal(serviceProvider.getSubscriptionStatus(eBookServiceName)==0,true,"Service thinks a subscribed user has not subscribed");

        serviceProvider.setDay(3);

        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==1,true,"Service is not picking up the fact that a user has expired");
        Assert.equal(serviceProvider.getSubscriptionStatus(eBookServiceName)==1,true,"Service is not picking up the fact that a user has expired");
    }

    //Check that the subscribeToTrial function returns true only for new users i.e. not for ones that have already subscribed or that have expired subscriptions
    function testSubscribeToTrial() public {

        //Subscribe to one service immediately and the other a day later so as the services expire at different times

        Assert.equal(serviceProvider.subscribeToTrial(filmRentalServiceName), true, "Subscription failed for new user");
        Assert.equal(serviceProvider.subscribeToTrial(filmRentalServiceName), false, "Subscription succeeded for user who is already subscribed and active");

        serviceProvider.setDay(2);

        Assert.equal(serviceProvider.subscribeToTrial(eBookServiceName), true, "Subscription failed for new user");
        Assert.equal(serviceProvider.subscribeToTrial(eBookServiceName), false, "Subscription succeeded for user who is already subscribed and active");

        Assert.equal(serviceProvider.subscribeToTrial(filmRentalServiceName), false, "Subscription succeeded for user who is already subscribed and expired");

        serviceProvider.setDay(3);

        Assert.equal(serviceProvider.subscribeToTrial(filmRentalServiceName), false, "Subscription succeeded for user who is already subscribed and expired");
        Assert.equal(serviceProvider.subscribeToTrial(eBookServiceName), false, "Subscription succeeded for user who is already subscribed and expired");
    }
}
