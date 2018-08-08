pragma solidity 0.4.24;

import "./Service.sol";

/**
 * Example contract that takes a service in its constructor, a film rental service in this example,
 * and wraps it in functionality that enables users to subscribe to a free trial for
 * a day.
 */
contract ServiceProvider {

    address public owner;

    Service private service;

    enum SubscriptionStatus {ACTIVE,EXPIRED,NOT_SUBSCRIBED}

    struct UserProfile {
        uint8 expirationDay;
        bool inUse;
    }

    mapping(string => UserProfile) private userProfiles;

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
    function getSubscriptionStatus(string username) view public returns(uint8) {
        uint8 expirationDay = userProfiles[username].expirationDay;
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
     * Subscribes the given user name, which means that they will be able to access
     * the service for a day.
     */
    function subscribeToTrial(string username) external returns (bool) {
        if(getSubscriptionStatus(username) != uint8(SubscriptionStatus.NOT_SUBSCRIBED)){
           return false;
        }

        uint8 expirationDay = currentDay + 1;
        userProfiles[username] = UserProfile(expirationDay, false);
        return true;
    }

    /**
     * Returns a URL from the service (a film in this case) that the user is subscribed to
     */
    function callService(string username) view external returns(string) {
        if(getSubscriptionStatus(username) != uint8(SubscriptionStatus.ACTIVE)) {
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

    modifier isOwner(address a) {
        require(a == owner);
        _;
    }

}
