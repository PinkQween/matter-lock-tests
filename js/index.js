const { Accessory, Characteristic, Service, UUID } = require('hap-nodejs');

// Create an accessory
const accessory = new Accessory('Door Lock', UUID.generate('Door Lock'));

// Add a lock service to the accessory
const lockService = new Service.LockMechanism('Lock', 'lock');

// Set the lock current state to unlocked initially
let currentState = Characteristic.LockCurrentState.UNSECURED;
let targetState = Characteristic.LockTargetState.UNSECURED;

// Add the lock current state characteristic
lockService
    .getCharacteristic(Characteristic.LockCurrentState)
    .on('get', callback => {
        callback(null, currentState);
    });

// Add the lock target state characteristic
lockService
    .getCharacteristic(Characteristic.LockTargetState)
    .on('get', callback => {
        callback(null, targetState);
    })
    .on('set', (value, callback) => {
        targetState = value;
        console.log('Target state set to', value === Characteristic.LockTargetState.SECURED ? 'locked' : 'unlocked');
        callback();
    });

// Add the lock service to the accessory
accessory.addService(lockService);

// Publish the accessory on the local network
const { AccessoryPublisher } = require('hap-nodejs/dist/lib/AccessoryPublisher');
const publisher = new AccessoryPublisher();
publisher.publish(accessory);

// Unpublish the accessory when the process ends
process.on('exit', () => {
    publisher.unpublishAll();
});
