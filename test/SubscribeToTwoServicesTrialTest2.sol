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
contract SubscribeToTwoServicesTrialTest2 {

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

    //Make sure the service being provided functions correctly when used and that only users who have valid subscriptions can use it
    function testUseService() public {

        //Subscribe to one service immediately and the other a day later so as the services expire at different times

        string memory result =  serviceProvider.callService(filmRentalServiceName);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is not subscribed and tries to use the service");
        serviceProvider.subscribeToTrial(filmRentalServiceName);
        result = serviceProvider.callService(filmRentalServiceName);
        Assert.equal(result,film,"Wrong film");

        result =  serviceProvider.callService(eBookServiceName);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is not subscribed and tries to use the service");

        serviceProvider.setDay(2);

        result =  serviceProvider.callService(filmRentalServiceName);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is expired and tries to use the service");

        serviceProvider.subscribeToTrial(eBookServiceName);
        result =  serviceProvider.callService(eBookServiceName);
        Assert.equal(result,book,"Wrong book");

        serviceProvider.setDay(3);

        result =  serviceProvider.callService(filmRentalServiceName);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is expired and tries to use the service");

        result =  serviceProvider.callService(eBookServiceName);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is expired and tries to use the service");
    }
}
