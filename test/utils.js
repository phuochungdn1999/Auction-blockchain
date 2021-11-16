
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

const skipTime = async (hour) => {
    await network.provider.send("evm_increaseTime", [hour * 3600])
    await network.provider.send("evm_mine")
}

const setTime = async (time) => { //1600000000
    await network.provider.send("evm_setNextBlockTimestamp", [time])
    await network.provider.send("evm_mine")
}


const toBNWeb3 = async (data) => {
    return web3.utils.toBN(data);
}

module.exports = {
    sleep, 
    skipTime,
    setTime,
    toBNWeb3
}
