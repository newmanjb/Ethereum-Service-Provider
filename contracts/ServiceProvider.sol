pragma solidity 0.4.24;

import "./Service.sol";

/**
 * A contract that takes a list of services in its constructor and wraps it in functionality
 * that enables users to subscribe to a free trial to one or more services for one day only
 * or to enter a paid subscription to one or more services, with the time period being
 * dependent on how much they pay.
 */
contract ServiceProvider {

    //A bit cheap but it makes it easier to test
    uint constant public feePerDayInWei = 3 wei;

    address public owner;

    enum SubscriptionStatus {ACTIVE,EXPIRED,NOT_SUBSCRIBED}

    //Service names to services
    mapping(string => Service) private services;

    struct SubscriptionProfile {
        uint expirationDay;
    }

    //This map is keyed by username with the values being other maps,
    //keyed by service name, that point to the profile for the user's subscription
    //to that service.
    mapping(address => mapping(string=>SubscriptionProfile)) private subscriptionProfiles;

    uint8 public currentDay;

    //Simple error message
    string constant public notsubscribed = "You are not subscribed";

    constructor(address[] memory _services) public  {
        owner = msg.sender;
        currentDay = 1;
        for(uint i = 0 ; i < _services.length; i++) {
            Service service = Service(_services[i]);
            services[service.getServiceName()] = service;
        }
    }

    /**
     * Returns whether the user's subscription is active (0), expired (1) or
     * non-existent (2)
     */
    function getSubscriptionStatus(string serviceName) view public returns(uint8) {
        address user = msg.sender;
        return doGetSubscriptionStatus(user, serviceName);
    }

    function doGetSubscriptionStatus(address user, string serviceName) view private returns (uint8) {
        uint expirationDay = subscriptionProfiles[user][serviceName].expirationDay;
        if(expirationDay == 0){
            return uint8(SubscriptionStatus.NOT_SUBSCRIBED);
        }
        else if(currentDay >= expirationDay) {
            return uint8(SubscriptionStatus.EXPIRED);
        }
        else {
            return uint8(SubscriptionStatus.ACTIVE);
        }
    }

    /**
     * Subscribes the given address to the free trial`, which means that they will be able to access
     * the service specified for a day.
     */
    function subscribeToTrial(string serviceName) external returns (bool) {
        address user = msg.sender;
        if(doGetSubscriptionStatus(user, serviceName) != uint8(SubscriptionStatus.NOT_SUBSCRIBED)){
           return false;
        }

        uint expirationDay = currentDay + 1;
        subscriptionProfiles[user][serviceName] = SubscriptionProfile(expirationDay);
        return true;
    }

    /**
     * Enables the caller to pay for a subscription to the given service for a number of days based on the
     * value provided.
     */
    function subscribeFor(string serviceName) external payable returns (uint) {

        address user = msg.sender;
        uint feeProvided = msg.value;
        uint numDaysPaidFor = feeProvided / feePerDayInWei;

        if(numDaysPaidFor < 1) {
            return 0;
        }

        uint newExpirationDay = currentDay + numDaysPaidFor;
        subscriptionProfiles[user][serviceName] = SubscriptionProfile(uint(newExpirationDay));
        return numDaysPaidFor;
    }

    /**
     * Fallback function for receiving ether
     */
    function () public payable {
    }

    /**
     * Returns a URL from the service that the user is subscribed to e.g. a URL they can
     * use to watch a film from a film rental service.
     */
    function callService(string serviceName) view external returns(string) {
        address user = msg.sender;
        if(doGetSubscriptionStatus(user, serviceName) != uint8(SubscriptionStatus.ACTIVE)) {
            return notsubscribed;
        }
        string memory result = services[serviceName].getFromService();
        return result;
    }

    /**
     * Used to tell the contract that the day has changed.  This affects user's subscriptions.
     * This can only be called by the owner of the contract and would need to be
     * called externally by the owner's systems at the end of each calendar day because,
     * at the time of writing, there is no reliable way to get the system time from
     * within a contract unless you want the block creation time.
     */
    function setDay(uint8 _day) external isOwner(msg.sender) {
        currentDay = _day;
    }

    function getDay() view external isOwner(msg.sender) returns (uint8) {
        return currentDay;
    }

    modifier isOwner(address a) {
        require(a == owner);
        _;
    }

}
