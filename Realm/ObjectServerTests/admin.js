#!/usr/bin/env node

const stitch = require('mongodb-stitch');

async function create() {
    const admin = await stitch.StitchAdminClientFactory.create("http://localhost:9090");

    await admin.login("unique_user@domain.com", "password");
    const profile = await admin.userProfile();
    const groupId = profile.roles[0].group_id;
    const appResponse = (await admin.apps(groupId).create({name: 'test'}));
    const appId = appResponse['_id'];

    const app = admin.apps(groupId).app(appId);

    let promises = []

    promises.push(app.authProviders().create({type: 'anon-user'}));
    promises.push(app.authProviders().create({
        type: 'local-userpass',
        config: {
        emailConfirmationUrl: 'http://foo.com',
        resetPasswordUrl: 'http://foo.com',
        confirmEmailSubject: 'Hi',
        resetPasswordSubject: 'Bye',
        autoConfirm: true
    }}));
    promises.push(app.authProviders().list().then(authProviders => {
        for (const provider of authProviders) {
            if (provider.type == 'api-key') {
                return app.authProviders().authProvider(provider._id).enable();
            }
        }
    }));

    await app.secrets().create({
        name: "BackingDB_uri",
        value: "mongodb://localhost:26000"
    });

    const serviceResponse = await app.services().create({
        "name": "mongodb1",
        "type": "mongodb",
        "config": {
            "uri": "mongodb://localhost:26000",
            "sync": {
                "state": "enabled",
                "database_name": "test_data",
                "partition": {
                    "key": "realm_id",
                    "type": "string",
                    "permissions": {
                        "read": true,
                        "write": true
                    }
                }
            }
        }
    });

    const dogRule = {
        "database": "test_data",
        "collection": "Dog",
        "roles": [{
            "name": "default",
            "apply_when": {},
            "insert": true,
            "delete": true,
            "additional_fields": {}
        }],
        "schema": {
            "properties": {
                "_id": {
                    "bsonType": "objectId"
                },
                "breed": {
                    "bsonType": "string"
                },
                "name": {
                    "bsonType": "string"
                },
                "realm_id": {
                    "bsonType": "string"
                }
            },
            "required": ["name"],
            "title": "Dog"
        }
    };

    const personRule = {
        "database": "test_data",
        "collection": "Person",
        "relationships": {
        },
        "roles": [{
            "name": "default",
            "apply_when": {},
            "write": true,
            "insert": true,
            "delete": true,
            "additional_fields": {}
        }],
        "schema": {
            "properties": {
                "_id": {
                    "bsonType": "objectId"
                },
                "age": {
                    "bsonType": "int"
                },
                "firstName": {
                    "bsonType": "string"
                },
                "lastName": {
                    "bsonType": "string"
                },
                "realm_id": {
                    "bsonType": "string"
                }
            },
            "required": ["firstName",
                         "lastName",
                         "age"],
            "title": "Person"
        }
    };

    const hugeSyncObjectRule = {
        "database": "test_data",
        "collection": "HugeSyncObject",
        "roles": [
                  {
            "name": "default",
            "apply_when": {},
            "insert": true,
            "delete": true,
            "additional_fields": {}
        }
                  ],
        "schema": {
            "properties": {
                "_id": {
                    "bsonType": "objectId"
                },
                "dataProp": {
                    "bsonType": "binData"
                },
                "realm_id": {
                    "bsonType": "string"
                }
            },
            "required": [
            ],
            "title": "HugeSyncObject"
        },
        "relationships": {
        }
    };

    const userDataRule = {
        "database": "test_data",
        "collection": "UserData",
        "roles": [
                  {
            "name": "default",
            "apply_when": {},
            "insert": true,
            "delete": true,
            "additional_fields": {}
        }
                  ],
        "schema": {
        },
        "relationships": {
        }
    };

    const rules = app.services().service(serviceResponse['_id']).rules();
    promises.push(rules.create(dogRule));
    promises.push(rules.create(personRule));
    promises.push(rules.create(hugeSyncObjectRule));
    promises.push(rules.create(userDataRule));
    promises.push(rules.create({
        "database": "test_data",
        "collection": "SwiftPerson",
        "roles": [{
            "name": "default",
            "apply_when": {},
            "insert": true,
            "delete": true,
            "additional_fields": {}
        }],
        "schema": {
            "properties": {
                "_id": {
                    "bsonType": "objectId"
                },
                "age": {
                    "bsonType": "int"
                },
                "firstName": {
                    "bsonType": "string"
                },
                "lastName": {
                    "bsonType": "string"
                },
                "realm_id": {
                    "bsonType": "string"
                }
            },
            "required": [
                         "firstName",
                         "lastName",
                         "age"
                         ],
            "title": "SwiftPerson"
        },
        "relationships": {
        }
    }));

    promises.push(app.sync().config().update({
        "development_mode_enabled": true
    }));

    promises.push(app.functions().create({
        "name": "sum",
        "private": false,
        "can_evaluate": {},
        "source": `
        exports = function(...args) {
            return parseInt(args.reduce((a,b) => a + b, 0));
        };
        `
    }));

    promises.push(app.functions().create({
        "name": "updateUserData",
        "private": false,
        "can_evaluate": {},
        "source": `
        exports = async function(data) {
            const user = context.user;
            const mongodb = context.services.get("mongodb1");
            const userDataCollection = mongodb.db("test_data").collection("UserData");
            await userDataCollection.updateOne(
                                               { "user_id": user.id },
                                               { "$set": data },
                                               { "upsert": true }
                                               );
            return true;
        };
        `
    }));

    promises.push(app.customUserData().update({
        "mongo_service_id": serviceResponse['_id'],
        "enabled": true,
        "database_name": "test_data",
        "collection_name": "UserData",
        "user_id_field": "user_id"
    }));
    
    await app.secrets().create({
        name: "gcm",
        value: "gcm"
    });
    
    promises.push(app.services().create({
        "name": "gcm",
        "type": "gcm",
        "config": {
            "senderId": "gcm"
        },
        "secret_config": {
            "apiKey": "gcm"
        },
        "version": 1
    }));

    await Promise.all(promises);

    process.stdout.write(appResponse['client_app_id']);
}

async function clean() {
    try {
        const admin = await stitch.StitchAdminClientFactory.create("http://localhost:9090");

        await admin.login("unique_user@domain.com", "password");
        const profile = await admin.userProfile();
        const groupId = profile.roles[0].group_id;
        const apps = await admin.apps(groupId).list();
        for (app in apps) {
            await admin.apps(groupId).app(app['_id']).remove();
        }
    } catch (error) {
    }
}

var args = process.argv.slice(2);

switch (args[0]) {
    case 'create':
        create();
        break;
    case 'clean':
        clean();
        break;
    default:
        process.stderr.write("Invalid arg: " + args[0]);
        break;
}
