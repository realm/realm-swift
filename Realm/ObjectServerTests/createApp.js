#!/usr/bin/env node

const stitch = require('mongodb-stitch');

async function main() {
    const admin = await stitch.StitchAdminClientFactory.create("http://localhost:9090");

    await admin.login("unique_user@domain.com", "password");
    const profile = await admin.userProfile();
    const groupId = profile.roles[0].group_id;
    const appResponse = (await admin.apps(groupId).create({name: 'test'}));
    const appId = appResponse['_id'];
    process.stdout.write(appResponse['client_app_id']);
    const app = admin.apps(groupId).app(appId);

    await app.authProviders().create({type: 'anon-user'});
    await app.authProviders().create({type: 'local-userpass', config: {
        emailConfirmationUrl: 'http://foo.com',
        resetPasswordUrl: 'http://foo.com',
        confirmEmailSubject: 'Hi',
        resetPasswordSubject: 'Bye',
        autoConfirm: true
    }});
}

main();
