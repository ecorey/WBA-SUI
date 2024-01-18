module prer::pre_r {

    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    
    
    struct ExampleObject has key { 
        id: UID
    }

    // non-entry create function
    public fun create(ctx: &mut TxContext): ExampleObject {
        ExampleObject { id: object::new(ctx) }
    }

    // entry create and transfer
    entry fun create_and_transfer(to: address, ctx: &mut TxContext) {
        transfer::transfer(create(ctx), to)
    }

    
}

module prer::object_example {

    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};

    struct ExampleObject has key { 
        id: UID
    }

    // non-entry create function
    public fun create(ctx: &mut TxContext): ExampleObject {
        ExampleObject { id: object::new(ctx) }
    }

    // entry create and transfer
    entry fun create_and_transfer(to: address, ctx: &mut TxContext) {
        transfer::transfer(create(ctx), to)
    }

    // SHARED OBJECT EXAMPLE
    const ENotEnough: u64 = 0;

    struct ExampleObjectCap has key { id: UID }

    struct ExampleObjectShop has key {

        id: UID,
        price: u64,
        balance: Balance<SUI>

    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(ExampleObjectCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        // Share the object 
        // transfer::share_object(ExampleObjectShop {
        //     id: object::new(ctx),
        //     price: 1000,
        //     balance: balance::zero()
        // })
    }

    public fun buy_example_object (
        shop: &mut ExampleObjectShop, payment: &mut Coin<SUI>, ctx: &mut TxContext    
    ) {
        assert!(coin::value(payment) >= shop.price, ENotEnough);

        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, shop.price);

        balance::join(&mut shop.balance, paid);

        transfer::transfer(ExampleObject {
            id: object::new(ctx)
        }, tx_context::sender(ctx))
    }

    // deconstruct and delete object
    public fun delete_example_object(e: ExampleObject) {
        let ExampleObject { id } = e;
        object::delete(id);
    }


    public fun collect_profits (
        _: &ExampleObjectCap, shop: &mut ExampleObjectShop, ctx: &mut TxContext
    ) : Coin<SUI> {

        let amount = balance::value(&shop.balance);
        coin::take(&mut shop.balance, amount, ctx)

    }

}



module prer::wrapper {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Wrapper<T: store> has key, store {
        id: UID, 
        contents: T
    }


    public fun contents<T: store>(c: &Wrapper<T>) : &T {
        &c.contents
    }


    public fun create<T: store> (
        contents: T, ctx: &mut TxContext
    ) : Wrapper<T> {
            Wrapper {
                contents, 
                id: object::new(ctx),
            }
    }


    public fun destroy<T: store> (c: Wrapper<T>) : T {
        let Wrapper { id, contents } = c;
        object::delete(id);
        contents
    }
    
}



module prer::profile {
    use sui::url::{Self, Url};
    use std::string::{Self, String};
    use sui::tx_context::TxContext;


    use prer::wrapper::{Self, Wrapper};


    struct ProfileInfo has store {
        name: String, 
        url: Url
    }


    public fun name(info: &ProfileInfo) : &String {
        &info.name
    }

    public fun url(info: &ProfileInfo) : &Url {
        &info.url
    }


    public fun create_profile(
        name: vector<u8>, url: vector<u8>, ctx: &mut TxContext
    ) : Wrapper<ProfileInfo> {

        let container = wrapper::create(ProfileInfo {
            name: string::utf8(name),
            url: url::new_unsafe_from_bytes(url)
        }, ctx);

        container
    }
    
}


module prer::restricted_transfer {

    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::sui::SUI;


    const EWrongAmount: u64 = 0;


    struct GovernmentCapability has key { id: UID }


    struct TitleDeed has key {
        id: UID,
    }

    struct LandRegistry has key {
        id: UID,
        balance: Balance<SUI>,
        fee: u64   
    }


    fun init(ctx: &mut TxContext) {

        transfer::transfer(GovernmentCapability {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::share_object( LandRegistry {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            fee: 10000
        })

    }


    public fun issue_title_deed(
        _: &GovernmentCapability,
        for: address, 
        ctx: &mut TxContext
    ) {
        transfer::transfer( TitleDeed {
            id: object::new(ctx)
        }, for)
    }

    public fun transfer_ownership (
        registry: &mut LandRegistry,
        paper: TitleDeed,
        fee: Coin<SUI>,
        to: address
    ) {

        assert!(coin::value(&fee) == registry.fee, EWrongAmount);

        balance::join(&mut registry.balance, coin::into_balance(fee));

        transfer::transfer(paper, to)

    }

}



//EVENTS
module prer::objects_with_events {

    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, ID, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};

    use sui::event;
    

    const ENotEnough: u64 = 0;

    struct StoreOwnerCap has key { id: UID }

    struct ExampleObject has key { id: UID }

    struct Store has key {
        id: UID, 
        price: u64, 
        balance: Balance<SUI>
    }


    struct ObjectBought has copy, drop {
        id: ID
    }


    struct ProfitsCollected has copy, drop {
        amount: u64
    }


    fun init(ctx: &mut TxContext) {

        transfer::transfer(StoreOwnerCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));

        transfer::share_object(Store {
            id: object::new(ctx),
            price: 1000,
            balance: balance::zero()
        })

    }



    public fun buy_example_object(
        shop: &mut Store, payment: &mut Coin<SUI>, ctx: &mut TxContext
    ) {
        assert!(coin::value(payment) >= shop.price, ENotEnough);

        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, shop.price);
        let id = object::new(ctx);

        balance::join(&mut shop.balance, paid);

        event::emit(ObjectBought { id: object::uid_to_inner(&id) });
        transfer::transfer(ExampleObject {id}, tx_context::sender(ctx))

    }


    


}