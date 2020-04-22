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

    await app.authProviders().create({type: 'anon-user'});
    await app.authProviders().create({type: 'local-userpass', config: {
        emailConfirmationUrl: 'http://foo.com',
        resetPasswordUrl: 'http://foo.com',
        confirmEmailSubject: 'Hi',
        resetPasswordSubject: 'Bye',
        autoConfirm: true
    }});
    const authProviders = await app.authProviders().list();
    for (const i in authProviders) {
        if (authProviders[i].type == 'api-key') {
            await app.authProviders().authProvider(authProviders[i]._id).enable();
            break;
        }
    }

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
                    "permissions": {
                        "read": true,
                        "write": true
                    }
                }
            }
        }
    });

    var dogRule = {
        "database": "test_data",
        "collection": "Dog",
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
            "required": [
                "name"
            ],
            "title": "Dog"
        }
    };

    var personRule = {
        "database": "test_data",
        "collection": "Person",
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
                "age": {
                    "bsonType": "int"
                },
                "dogs": {
                    "bsonType": "array",
                    "items": {
                        "bsonType": "objectId",
                    }
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
                "age",
                "dogs"
            ],
            "title": "Person"
        },
        "relationships": {
          "dogs": {
            "foreign_key": "_id",
            "ref": "#/stitch/mongodb1/test_data/Dog",
            "is_list": true
          }
        }
    };

    await app.services().service(serviceResponse['_id']).rules().create(dogRule);
    await app.services().service(serviceResponse['_id']).rules().create(personRule);

    dogRule.collection = "SwiftDog";
    dogRule.schema.title = "SwiftDog";
    personRule.schema.title = "SwiftPerson";
    personRule.collection = "SwiftPerson";
    personRule.relationships.dogs.ref = "#/stitch/mongodb1/test_data/SwiftDog"

    await app.services().service(serviceResponse['_id']).rules().create(dogRule);
    await app.services().service(serviceResponse['_id']).rules().create(personRule);
    
    await app.sync().config().update({
        "development_mode_enabled": true
    });
    
    process.stdout.write(appResponse['client_app_id']);
}

async function last() {
    const admin = await stitch.StitchAdminClientFactory.create("http://localhost:9090");

    await admin.login("unique_user@domain.com", "password");
    const profile = await admin.userProfile();
    const groupId = profile.roles[0].group_id;
    const apps = await admin.apps(groupId).list();

    process.stdout.write(apps[apps.length - 1]['client_app_id']);
}

async function clean() {
    const admin = await stitch.StitchAdminClientFactory.create("http://localhost:9090");

    await admin.login("unique_user@domain.com", "password");
    const profile = await admin.userProfile();
    const groupId = profile.roles[0].group_id;
    const apps = await admin.apps(groupId).list();
    for (app in apps) {
        await admin.apps(groupId).app(app['_id']).remove();
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
    case 'last':
        last();
        break;
    default:
        process.stderr.write("Invalid arg: " + args[0]);
        break;
}
