#[starknet::interface]
trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
}

#[starknet::contract]
mod Counter {
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: IKillSwitchDispatcher,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        value: u32
    }

    #[constructor]
    fn constructor(ref self: ContractState, counter: u32, ks_addr: ContractAddress) {
        self.counter.write(counter);
        self.kill_switch.write(IKillSwitchDispatcher { contract_address: ks_addr });
    }

    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let ks_contract = self.kill_switch.read();

            if ks_contract.is_active() {
                self.counter.write(self.get_counter() + 1);
                self.emit(CounterIncreased { value: self.get_counter() })
            }
        }
    }
}
