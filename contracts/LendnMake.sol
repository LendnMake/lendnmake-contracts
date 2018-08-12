pragma solidity ^0.4.23;

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

contract DXLT is ERC721Token {
    uint256 totalSupply_;
    
    struct DXL{
        uint256 uniqueID;
        string uniqueness;
    }
    
    DXL[] dxls;

    address public owner;
    mapping(address => uint256) balances;
    uint256[] internal allTokens;
    mapping (address => uint256[]) internal ownedTokens;
    mapping (uint256 => address) internal tokenOwner;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex; 

    //Mapping from token id to position in the allTokens array 
    mapping(uint256 => uint256) internal allTokensIndex;

    mapping (address => uint256) internal ownedTokensCount;

    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    
    function checkOwner(uint256 _tokenId) public returns(bool){
        if(exists(_tokenId) && tokenOwner[_tokenId]==msg.sender){
            return true;
        }
        return false;
    }

    function DXLT(string _name, string _symbol) public ERC721Token(_name, _symbol) {
        owner = msg.sender;
    }
        // super.name_ = _name; super.symbol_ = _symbol;}
    
    function mint(address _to, uint256 _uniqueID, string _uniqueness) onlyOwner public 
    returns (bool) 
    {
        totalSupply_ = totalSupply_.add(1);
        balances[_to] = balances[_to].add(1);
        
        DXL memory _dxl = DXL({uniqueID:_uniqueID, uniqueness:_uniqueness});
        
        uint _dxlID = dxls.push(_dxl) -1;
        
        super._mint(_to, _dxlID);
        super._setTokenURI(_dxlID, _uniqueness);
        // Transfer(address(0), _to, _uniqueID, _uniqueness); return true;
    }

    /**
    * Custom accessor to create a unique token
    */
    function mintUniqueTokenTo(
        address _to,
        uint256 _tokenId,
        string  _tokenURI
    ) public
    {
        require(exists(_tokenId));
        super._mint(_to, _tokenId);
        super._setTokenURI(_tokenId, _tokenURI);
    }

    function transfer(address _to, uint256 _value) public returns (bool) { 
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
    //     transferFrom(_from, _to, _tokenId);
    //     require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    // }

    // function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
    //     if (!_to.isContract()) {
    //         return true;
    //     }
    //     bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    //     return (retval == ERC721_RECEIVED);
    // }
}

//////////////////////
// DAI CONTRACT - Dai another day
//////////////////////

contract TokenInterface {
    function balanceOf(address) public returns (uint);
    function allowance(address, address) public returns (uint);
    function approve(address, uint) public;
    function transfer(address,uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
    function deposit() public payable;
    function withdraw(uint) public;
}

contract DaiContract is TokenInterface {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract OtcInterface {
    function sellAllAmount(address, uint, address, uint) public returns (uint);
    function buyAllAmount(address, uint, address, uint) public returns (uint);
    function getPayAmount(address, address, uint) public constant returns (uint);
}

contract OasisDirectProxy is DaiContract {
    function withdrawAndSend(TokenInterface wethToken, uint wethAmt) internal {
        wethToken.withdraw(wethAmt);
        require(msg.sender.call.value(wethAmt)());
    }

    function sellAllAmount(OtcInterface otc, TokenInterface payToken, uint payAmt, TokenInterface buyToken, uint minBuyAmt) public returns (uint buyAmt) {
        require(payToken.transferFrom(msg.sender, this, payAmt));
        if (payToken.allowance(this, otc) < payAmt) {
            payToken.approve(otc, uint(-1));
        }
        buyAmt = otc.sellAllAmount(payToken, payAmt, buyToken, minBuyAmt);
        require(buyToken.transfer(msg.sender, buyAmt));
    }

    function sellAllAmountPayEth(OtcInterface otc, TokenInterface wethToken, TokenInterface buyToken, uint minBuyAmt) public payable returns (uint buyAmt) {
        wethToken.deposit.value(msg.value)();
        if (wethToken.allowance(this, otc) < msg.value) {
            wethToken.approve(otc, uint(-1));
        }
        buyAmt = otc.sellAllAmount(wethToken, msg.value, buyToken, minBuyAmt);
        require(buyToken.transfer(msg.sender, buyAmt));
    }

    function sellAllAmountBuyEth(OtcInterface otc, TokenInterface payToken, uint payAmt, TokenInterface wethToken, uint minBuyAmt) public returns (uint wethAmt) {
        require(payToken.transferFrom(msg.sender, this, payAmt));
        if (payToken.allowance(this, otc) < payAmt) {
            payToken.approve(otc, uint(-1));
        }
        wethAmt = otc.sellAllAmount(payToken, payAmt, wethToken, minBuyAmt);
        withdrawAndSend(wethToken, wethAmt);
    }

    function buyAllAmount(OtcInterface otc, TokenInterface buyToken, uint buyAmt, TokenInterface payToken, uint maxPayAmt) public returns (uint payAmt) {
        uint payAmtNow = otc.getPayAmount(payToken, buyToken, buyAmt);
        require(payAmtNow <= maxPayAmt);
        require(payToken.transferFrom(msg.sender, this, payAmtNow));
        if (payToken.allowance(this, otc) < payAmtNow) {
            payToken.approve(otc, uint(-1));
        }
        payAmt = otc.buyAllAmount(buyToken, buyAmt, payToken, payAmtNow);
        require(buyToken.transfer(msg.sender, min(buyAmt, buyToken.balanceOf(this)))); // To avoid rounding issues we check the minimum value
    }

    function buyAllAmountPayEth(OtcInterface otc, TokenInterface buyToken, uint buyAmt, TokenInterface wethToken) public payable returns (uint wethAmt) {
        // In this case user needs to send more ETH than a estimated value, then contract will send back the rest
        wethToken.deposit.value(msg.value)();
        if (wethToken.allowance(this, otc) < msg.value) {
            wethToken.approve(otc, uint(-1));
        }
        wethAmt = otc.buyAllAmount(buyToken, buyAmt, wethToken, msg.value);
        require(buyToken.transfer(msg.sender, min(buyAmt, buyToken.balanceOf(this)))); // To avoid rounding issues we check the minimum value
        withdrawAndSend(wethToken, sub(msg.value, wethAmt));
    }

    function buyAllAmountBuyEth(OtcInterface otc, TokenInterface wethToken, uint wethAmt, TokenInterface payToken, uint maxPayAmt) public returns (uint payAmt) {
        uint payAmtNow = otc.getPayAmount(payToken, wethToken, wethAmt);
        require(payAmtNow <= maxPayAmt);
        require(payToken.transferFrom(msg.sender, this, payAmtNow));
        if (payToken.allowance(this, otc) < payAmtNow) {
            payToken.approve(otc, uint(-1));
        }
        payAmt = otc.buyAllAmount(wethToken, wethAmt, payToken, payAmtNow);
        withdrawAndSend(wethToken, wethAmt);
    }

    function() public payable {}
}

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

// DSProxy
// Allows code execution using a persistant identity This can be very
// useful to execute a sequence of atomic actions. Since the owner of
// the proxy can be changed, this allows for dynamic ownership models
// i.e. a multisig
contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache;  // global cache for contracts

    function DSProxy(address _cacheAddr) public {
        require(setCache(_cacheAddr));
    }

    function() public payable {
    }

    // use the proxy to execute calldata _data on contract _code
    function execute(bytes _code, bytes _data)
        public
        payable
        returns (address target, bytes32 response)
    {
        target = cache.read(_code);
        if (target == 0x0) {
            // deploy contract & store its address in cache
            target = cache.write(_code);
        }

        response = execute(target, _data);
    }

    function execute(address _target, bytes _data)
        public
        auth
        note
        payable
        returns (bytes32 response)
    {
        require(_target != 0x0);

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)      // load delegatecall output
            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(0, 0)
            }
        }
    }

    //set new cache
    function setCache(address _cacheAddr)
        public
        auth
        note
        returns (bool)
    {
        require(_cacheAddr != 0x0);        // invalid cache address
        cache = DSProxyCache(_cacheAddr);  // overwrite cache
        return true;
    }
}

// DSProxyFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract DSProxyFactory {
    event Created(address indexed sender, address proxy, address cache);
    mapping(address=>bool) public isProxy;
    DSProxyCache public cache = new DSProxyCache();

    // deploys a new proxy instance
    // sets owner of proxy to caller
    function build() public returns (DSProxy proxy) {
        proxy = build(msg.sender);
    }

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(address owner) public returns (DSProxy proxy) {
        proxy = new DSProxy(cache);
        Created(owner, address(proxy), address(cache));
        proxy.setOwner(owner);
        isProxy[proxy] = true;
    }
}

// DSProxyCache
// This global cache stores addresses of contracts previously deployed
// by a proxy. This saves gas from repeat deployment of the same
// contracts and eliminates blockchain bloat.

// By default, all proxies deployed from the same factory store
// contracts in the same cache. The cache a proxy instance uses can be
// changed.  The cache uses the sha3 hash of a contract's bytecode to
// lookup the address
contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
            case 1 {
                // throw if contract failed to deploy
                revert(0, 0)
            }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}

contract ProxyCreationAndExecute is OasisDirectProxy {
    TokenInterface wethToken;

    function ProxyCreationAndExecute(address wethToken_) {
        wethToken = TokenInterface(wethToken_);
    }

    function createAndSellAllAmount(DSProxyFactory factory, OtcInterface otc, TokenInterface payToken, uint payAmt, TokenInterface buyToken, uint minBuyAmt) public returns (DSProxy proxy, uint buyAmt) {
        proxy = factory.build(msg.sender);
        buyAmt = sellAllAmount(otc, payToken, payAmt, buyToken, minBuyAmt);
    }

    function createAndSellAllAmountPayEth(DSProxyFactory factory, OtcInterface otc, TokenInterface buyToken, uint minBuyAmt) public payable returns (DSProxy proxy, uint buyAmt) {
        proxy = factory.build(msg.sender);
        buyAmt = sellAllAmountPayEth(otc, wethToken, buyToken, minBuyAmt);
    }

    function createAndSellAllAmountBuyEth(DSProxyFactory factory, OtcInterface otc, TokenInterface payToken, uint payAmt, uint minBuyAmt) public returns (DSProxy proxy, uint wethAmt) {
        proxy = factory.build(msg.sender);
        wethAmt = sellAllAmountBuyEth(otc, payToken, payAmt, wethToken, minBuyAmt);
    }

    function createAndBuyAllAmount(DSProxyFactory factory, OtcInterface otc, TokenInterface buyToken, uint buyAmt, TokenInterface payToken, uint maxPayAmt) public returns (DSProxy proxy, uint payAmt) {
        proxy = factory.build(msg.sender);
        payAmt = buyAllAmount(otc, buyToken, buyAmt, payToken, maxPayAmt);
    }

    function createAndBuyAllAmountPayEth(DSProxyFactory factory, OtcInterface otc, TokenInterface buyToken, uint buyAmt) public payable returns (DSProxy proxy, uint wethAmt) {
        proxy = factory.build(msg.sender);
        wethAmt = buyAllAmountPayEth(otc, buyToken, buyAmt, wethToken);
    }

    function createAndBuyAllAmountBuyEth(DSProxyFactory factory, OtcInterface otc, uint wethAmt, TokenInterface payToken, uint maxPayAmt) public returns (DSProxy proxy, uint payAmt) {
        proxy = factory.build(msg.sender);
        payAmt = buyAllAmountBuyEth(otc, wethToken, wethAmt, payToken, maxPayAmt);
    }

    function() public payable {
        require(msg.sender == address(wethToken));
    }
}

//////////////////////
// LEND'N'MAKE CONTRACT - depends on the DXL & DAI contract for locking ownership & transfer assets
//////////////////////
contract LendnMake {
    address public owner;
    
    address public borrower;
    address public lender;
    address internal potentialLender;
    
    address public dxlAddress;
    address public daiAddress;
    
    uint256 public asset_;
    uint256 public marketPrice_;
    uint256 public floorAmt_;
    uint256 public ceilAmt_;
    uint256 public rate_;
    uint256 public period_;
    
    bool public assetLocked;
    bool internal borrowerPaid;
    uint256 public loanBalance;
    uint256 internal deadline;
    
    uint256 public bestBid;
    uint256 public bidCountLimit;
    uint256 public bidCallCounter;
    bool public bidLiveStatus;
    
    modifier isLender(){
        require(msg.sender==lender);
        _;
    }
    
    modifier isBorrower(){
        require(msg.sender==borrower);
        _;
    }
    
    function LendnMake(uint256 _tokenId, uint256 _desiredAmt, uint256 _marketPrice, uint256 _desiredRate, uint256 _desiredPeriod) {
        owner = msg.sender;    
        asset_ = _tokenId;
        marketPrice_ = _marketPrice;
        floorAmt_ = _desiredAmt;
        ceilAmt_ = _marketPrice - (3*(_marketPrice))/10;
        rate_ = _desiredRate;
        period_ = _desiredPeriod;
        deadline = now + 3600*period_;
        lockAsset();
    }
    
    function Bid2Lend(uint256 _bidAmt) {
        require(msg.sender!=borrower && assetLocked==true);
        if(bidLiveStatus==true && _bidAmt > bestBid && _bidAmt < ceilAmt_) {
            bestBid = _bidAmt;
            potentialLender = msg.sender;
            bidCallCounter = bidCallCounter + 1;
            if(bidCallCounter==bidCountLimit) {
                bidLiveStatus = false;
            }
            lender = potentialLender;
        }
    }
    
    function lendDai() isLender internal returns(bool){
        require(assetLocked==true);
        DaiContract daic = DaiContract(daiAddress);
        daic.transfer(borrower, bestBid);
        loanBalance = bestBid;
        owner = lender;
    }
    
    function DAIInterface(address _DAIAddress) {
        daiAddress = _DAIAddress;
    }
    
    function DXLInterface(address _DXLAddress) {
        dxlAddress = _DXLAddress;
    }
    
    function lockAsset() internal returns(bool) {
        DXLT dxlt = DXLT(dxlAddress);
        dxlt.safeTransferFrom(borrower, address(this), asset_);
        assetLocked = true;
        return true;
    }
    
    function payBack(uint256 _payBackAmt) isBorrower public returns(bool){
        DaiContract daic = DaiContract(daiAddress);
        require(daic.transfer(lender, _payBackAmt));
        if(loanBalance - _payBackAmt==0){
            borrowerPaid = true;
        }
        else{
            loanBalance = loanBalance - _payBackAmt;
            borrowerPaid = false;
        }
    }
    
    // function TickTock() public returns(bool) {
    //     
    //     // oraclize_query(deadline, "URL", )
        
    // }
    
    function resolveDebt() public returns(bool) {
        require(now>=deadline);
        if(borrowerPaid){
            unlock2Borrower();
        }
        else{
            unlock2Lender();
        }
    }
    
    function unlock2Borrower() internal returns(bool) {
        DXLT dxlt = DXLT(dxlAddress);
        dxlt.safeTransferFrom(address(this), borrower, asset_);
        return true;
    }
    
    function unlock2Lender() internal returns(bool) {
        DXLT dxlt = DXLT(dxlAddress);
        dxlt.safeTransferFrom(address(this), lender, asset_);
        return true;
    }
    
    function checkLock() internal returns(bool){
        DXLT dxlt = DXLT(dxlAddress);
        return dxlt.checkOwner(asset_);
    }
}
