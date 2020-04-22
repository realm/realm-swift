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

    process.stdout.write(appResponse['client_app_id']);
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
    default:
        process.stderr.write("Invalid arg: " + args[0]);
        break;
}
