const ROS = require('realm-object-server');
const fs = require('fs');
const http = require('http');
const httpProxy = require('http-proxy');
const os = require('os');
const path = require('path');

// Bypass the mandatory email prompt.
process.env.ROS_TOS_EMAIL_ADDRESS = 'ci@realm.io';
process.env.DOCKER_DATA_PATH = '/tmp';

// Don't bother calling fsync() because we're throwing away all the files
// between runs anyway
process.env.REALM_DISABLE_SYNC_TO_DISK = 'true';

// Workaround for <https://github.com/realm/realm-object-server-private/issues/950>.
process.env.ROS_SUPERAGENT_RETRY_DELAY = '0';

// Enable timestamps in the logs
process.env.ROS_LOG_TIMESTAMP = '1';

if (!process.env.SYNC_WORKER_FEATURE_TOKEN) {
    try {
        require(os.homedir() + '/.ros-feature-token.js');
    }
    catch (e) {
        console.error('ROS feature token not found. Running Object Server tests requires setting the SYNC_WORKER_FEATURE_TOKEN environment variable.');
        process.exit(1);
    }
}

// A "email handler" which actually just writes the tokens to files that the
// tests can read
class PasswordEmailHandler {
    constructor(dataRoot) {
        this.dataRoot = dataRoot;
        fs.mkdirSync(this.dataRoot);
    }

    resetPassword(email, token, userAgent, remoteIp) {
        fs.writeFileSync(path.join(this.dataRoot, email), token);
        return new Promise(r => setTimeout(r, 0));
    }

    confirmEmail(email, token) {
        fs.writeFileSync(path.join(this.dataRoot, email), token);
        return new Promise(r => setTimeout(r, 0));
    }
}

class Proxy {
    constructor(listenPort, targetPort) {
        this.proxy = httpProxy.createProxyServer({target: `http://127.0.0.1:${targetPort}`, ws: true});
        this.proxy.on('error', e => {
            console.log('proxy error', e);
        });
        this.server = http.createServer((req, res) => {
            this.web(req, res);
        });
        this.server.on('upgrade', (req, socket, head) => {
            this.ws(req, socket, head);
        });
        this.server.listen(listenPort);
    }

    stop() {
        this.server.close();
        this.proxy.close();
    }

    web(req, res) {
        this.proxy.web(req, res);
    }

    ws(req, socket, head) {
        this.proxy.ws(req, socket, head);
    }
}

// A simple proxy server that runs in front of ROS and validates custom headers
class HeaderValidationProxy extends Proxy {
    web(req, res) {
        if (this.validate(req)) {
            this.proxy.web(req, res);
        }
        else {
            res.writeHead(400);
            res.end('Missing X-Allow-Connection header');
        }
    }
    ws(req, socket, head) {
        if (this.validate(req)) {
            this.proxy.ws(req, socket, head);
        }
        else {
            socket.end('HTTP/1.1 400 Bad Request\r\n\r\n');
        }
    }
    validate(req) {
        return !!req.headers['x-allow-connection'];
    }
}

// A proxy which sits in front of ROS and takes a long time to establish connections
class SlowConnectingWebProxy extends Proxy {
    web(req, res) {
        setTimeout(() => this.proxy.web(req, res), 2000);
    }
}
class SlowConnectingWsProxy extends Proxy {
    ws(req, socket, head) {
        setTimeout(() => this.proxy.ws(req, socket, head), 2000);
    }
}

const server = new ROS.BasicServer();
server.start({
    // The desired logging threshold. Can be one of: all, trace, debug, detail, info, warn, error, fatal, off)
    logLevel: 'off',

    // For all the full list of configuration parameters see:
    // https://realm.io/docs/realm-object-server/latest/api/ros/interfaces/serverconfig.html

    address: '0.0.0.0',
    port: 9080,
    httpsPort: 9443,

    https: true,
    httpsKeyPath: __dirname + '/certificates/localhost-cert-key.pem',
    httpsCertChainPath: __dirname + '/certificates/localhost-cert.pem',
    httpsForInternalComponents: false,

    dataPath: process.argv[2],
    authProviders: [
        new ROS.auth.DebugAuthProvider(),
        new ROS.auth.PasswordAuthProvider({
            autoCreateAdminUser: true,
            emailHandler: new PasswordEmailHandler(path.join(process.argv[2], 'email')),
        }),
    ],
    autoKeyGen: true,

    // Disable the legacy Realm-based permissions service
    permissionServiceConfigOverride: (config) => {
        config.enableManagementRealmReflection = false;
        config.enablePermissionRealmReflection = false;
    },
}).then(() => {
    console.log('started');
    fs.closeSync(1);
}).catch(err => {
    console.error(`Error starting Realm Object Server: ${err.message}`)
});
new HeaderValidationProxy(9081, 9080);
new SlowConnectingWebProxy(9082, 9080);
new SlowConnectingWsProxy(9083, 9080);
