pragma solidity 0.4.24;


import "./Service.sol";


/**
 * Simple example service that returns the URL to a film
 */
contract FilmRentalService is Service {


    function getFromService() external pure returns (string) {
        return "www.getMyFilm.com/logan";
    }
}

