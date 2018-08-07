pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ServiceProvider.sol";
import "../contracts/FilmRentalService.sol";

/**
 * Unit tests for the ServiceProvider contract
 */
contract ServiceProviderTest {

    ServiceProvider private serviceProvider;

    string constant private user1 = "user1";
    string constant private user2 = "user2";
    string constant private user3 = "user3";
    string constant private user4 = "user4";

    string constant private film = "www.getMyFilm.com/logan";


    function beforeEachTest() public {
        //Create a new service provider
        serviceProvider = new ServiceProvider(DeployedAddresses.FilmRentalService());
    }

    function testOwner() public {
        Assert.equal(serviceProvider.owner(), this, "Owner should be the deployer");
    }

    //Make sure that the owner can update the day correctly
    function testCurrentDay() public {
       Assert.equal(serviceProvider.currentDay()==1, true, "Current day does not have correct initial value");
       serviceProvider.setDay(2);
       Assert.equal(serviceProvider.currentDay()==2, true, "Current day was not set correctly");
    }

    //Cycle a user through the different stages of subscription i.e.
    //Not subscribed
    //subscribed
    //expired
    //and make sure that the contract returns the correct subscription status each time
    function testSubscriptionStatus() public {
        Assert.equal(serviceProvider.getSubscriptionStatus(user1)==2,true,"Service thinks a non-subscribed user has subscribed");
        serviceProvider.subscribeToTrial(user1);
	      Assert.equal(serviceProvider.getSubscriptionStatus(user1)==0,true,"Service thinks a subscribed user has not subscribed");
        serviceProvider.setDay(2);
        Assert.equal(serviceProvider.getSubscriptionStatus(user1)==1,true,"Service is not picking up the fact that a user has expired");
        //Move on one more day and make sure they're still expired
        serviceProvider.setDay(3);
        Assert.equal(serviceProvider.getSubscriptionStatus(user1)==1,true,"Service is not picking up the fact that a user has expired");
    }

    //Check that the subscribe function returns true only for new users i.e. not for ones that have already subscribed or that have expired subscriptions
    function testSubscribe() public {
        Assert.equal(serviceProvider.subscribeToTrial(user1), true, "Subscription failed for new user");
        Assert.equal(serviceProvider.subscribeToTrial(user1), false, "Subscription succeeded for user who is already subscribed and active");
        serviceProvider.setDay(2);
        Assert.equal(serviceProvider.subscribeToTrial(user1), false, "Subscription succeeded for user who is already subscribed and expired");
    }

    //Make sure the service being provided functions correctly when used and that only users who have valid subscriptions can use it
    function testUseService() public {
        string memory result =  serviceProvider.callService(user1);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is not subscribed and tries to use the service");
        serviceProvider.subscribeToTrial(user1);
        result = serviceProvider.callService(user1);
        Assert.equal(result,film,"Wrong film");
        serviceProvider.setDay(2);
        result =  serviceProvider.callService(user1);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is expired and tries to use the service");
    }

    //Make sure that the service provider functions as expected when there is >1 user by subscribing 2 users and ensuring that they can use the service, expiring them
    //by moving on by one day, and then repeating the process with another 2 users.
    function testWithMultipleUsers() public {

        serviceProvider.subscribeToTrial(user1);
        serviceProvider.subscribeToTrial(user2);

        Assert.equal(serviceProvider.callService(user1),film,"Wrong film");
        Assert.equal(serviceProvider.callService(user2),film,"Wrong film");

        serviceProvider.setDay(2);

        Assert.equal(serviceProvider.callService(user1),serviceProvider.notsubscribed(),"Wrong film");
        Assert.equal(serviceProvider.callService(user2),serviceProvider.notsubscribed(),"Wrong film");

        serviceProvider.subscribeToTrial(user3);
        serviceProvider.subscribeToTrial(user4);

        Assert.equal(serviceProvider.callService(user3),film,"Wrong film");
        Assert.equal(serviceProvider.callService(user4),film,"Wrong film");

        serviceProvider.setDay(3);

        Assert.equal(serviceProvider.callService(user3),serviceProvider.notsubscribed(),"Wrong film");
        Assert.equal(serviceProvider.callService(user4),serviceProvider.notsubscribed(),"Wrong film");
    }
}
