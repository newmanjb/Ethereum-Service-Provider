pragma solidity 0.4.24;

import "./Service.sol";

/**
 * A contract that takes a service in its constructor and wraps it in functionality
 * that enables users to subscribe to a free trial for a day or to enter a paid subscription
 * for more than one day.  A film rental service is used in the unit tests.
 */
contract ServiceProvider {

    //A bit cheap but it makes it easier to test
    uint constant public feePerDayInWei = 3 wei;

    address public owner;

    Service private service;

    enum SubscriptionStatus {ACTIVE,EXPIRED,NOT_SUBSCRIBED}

    struct UserProfile {
        uint expirationDay;
    }

    mapping(address => UserProfile) private userProfiles;

    uint8 public currentDay;

    //Simple error message
    string constant public notsubscribed = "You are not subscribed";

    constructor(address _service) public  {
        owner = msg.sender;
        currentDay = 1;
        service = Service(_service);
    }

    /**
     * Returns whether the user's subscription is active (0), expired (1) or
     * non-existent (2)
     */
    function getSubscriptionStatus() view public returns(uint8) {
        address user = msg.sender;
        return doGetSubscriptionStatus(user);
    }

    function doGetSubscriptionStatus(address user) view private returns (uint8) {
        uint expirationDay = userProfiles[user].expirationDay;
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
     * the service for a day.
     */
    function subscribeToTrial() external returns (bool) {
        address user = msg.sender;
        if(doGetSubscriptionStatus(user) != uint8(SubscriptionStatus.NOT_SUBSCRIBED)){
           return false;
        }

        uint expirationDay = currentDay + 1;
        userProfiles[user] = UserProfile(expirationDay);
        return true;
    }

    /**
     * Enables the caller to pay for a subscription for a number of days based on the
     * value provided.
     */
    function subscribeFor() external payable returns (uint) {

        address user = msg.sender;
        uint feeProvided = msg.value;
        uint numDaysPaidFor = feeProvided / feePerDayInWei;

        if(numDaysPaidFor < 1) {
            return 0;
        }

        uint newExpirationDay = currentDay + numDaysPaidFor;
        userProfiles[user] = UserProfile(uint(newExpirationDay));
        return numDaysPaidFor;
    }

    /**
     * Fallback function for receiving ether
     */
    function () public payable {
    }

    /**
     * Returns a URL from the service that the user is subscribed to
     */
    function callService() view external returns(string) {
        address user = msg.sender;
        if(doGetSubscriptionStatus(user) != uint8(SubscriptionStatus.ACTIVE)) {
            return notsubscribed;
        }
        string memory result = service.getFromService();
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
