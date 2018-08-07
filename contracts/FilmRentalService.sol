pragma solidity 0.4.24;


/**
 * Simple example service that returns the URL to a film
 */
contract FilmRentalService {


    function getFromService() external pure returns (string) {
        return "www.getMyFilm.com/logan";
    }
}
