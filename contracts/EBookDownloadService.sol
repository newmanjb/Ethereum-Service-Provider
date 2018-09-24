pragma solidity 0.4.24;


import "./Service.sol";


/**
 * Simple example service that returns the URL to a book download
 */
contract EBookDownloadService is Service {


    function getFromService() external pure returns (string) {
        return "www.ebooks.com/fiftyShadesBarrelScraping_whatChristianGreysHamsterSaw";
    }

    function getServiceName() external pure returns (string) {
        return "EBookDownloadService";
    }
}
