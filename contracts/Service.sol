pragma solidity 0.4.24;


/**
 * Should be used by all services that the service provider provides.
 */
interface Service {
    function getFromService() external pure returns (string);
}
