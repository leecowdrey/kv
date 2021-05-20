//
//  npm install body-parser
//  npm install express
//  npm express-basic-auth
//
const express = require('express');
const basicAuth = require('express-basic-auth')
const bodyParser = require('body-parser')
const app = express();
const {
    exec
} = require("child_process");
var jsonParser = bodyParser.json()

// app.use(basicAuth( { authorizer: myAuthorizer } ))
// function myAuthorizer(username, password) {
//     const userMatches = basicAuth.safeCompare(username, 'customuser')
//     const passwordMatches = basicAuth.safeCompare(password, 'custompassword')
//
//     return userMatches & passwordMatches
// }
app.use(basicAuth({
    users: {
        "admin": "admin",
        "lee": "lee",
        "fred": "fred",
    },
    unauthorizedResponse: getUnauthorizedResponse
}))

function getUnauthorizedResponse(req) {
  if (req.hasOwnProperty("auth")) {
    if (req.auth.hasOwnProperty("user")) {
      console.log("request:"+req.auth.user+":Not Authorized");
    } else {
      console.log("request:Not Authorized");
    }
  } else {
    console.log("request:Not Authorized");
  }
    return req.auth ?
        ("Invalid Credentials:" + req.auth.user + ":Not Authorized") :
        "Invalid Credentials:Not Authorized"
}

app.use(bodyParser.urlencoded({
    extended: true
}))

app.listen(8080, function() {
    console.log("listening on ::8080")
})

app.get('*', function(req, res) {
    var cmd = "/usr/bin/kv get " + req.path;
    console.log(req.auth.user+":"+cmd);
    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            res.status(500).send(`${error.message}`);
            return;
        }
        if (stderr) {
            res.status(404).send(`${stderr}`);
            return;
        }
        res.setHeader('content-type', 'application/json');
        res.status(200).send('{"value":"'+`${stdout}`.replace(/"/gm,"\\\"").replace(/(\r\n|\n|\r)/gm,"")+'"}');
    });
})

app.put('*', jsonParser, function(req, res) {
    var cmd = "/usr/bin/kv put " + req.path + " " + req.body.value;
    console.log(req.auth.user+":"+cmd);
    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            res.status(501).send(`${error.message}`);
            return;
        }
        if (stderr) {
            res.status(404).send(`${stderr}`)
            return;
        }
        res.status(201).send(`${stdout}`);
    });
})

app.patch('*', function(req, res) {
    var cmd = "/usr/bin/kv dump " + req.path;
    console.log(req.auth.user+":"+cmd);
    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            res.status(500).send(`${error.message}`);
            return;
        }
        if (stderr) {
            res.status(404).send(`${stderr}`);
            return;
        }
        res.status(200).send(`${stdout}`);
    });
})

app.head('*', function(req, res) {
    var cmd = "/usr/bin/kv list " + req.path;
    console.log(req.auth.user+":"+cmd);
    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            res.status(500).send(`${error.message}`);
            return;
        }
        if (stderr) {
            res.status(404).send(`${stderr}`);
            return;
        }
        res.status(200).send(`${stdout}`);
    });
})

app.options('*', function(req, res) {
    var cmd = "/usr/bin/kv";
    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            res.status(500).send(`${error.message}`);
            return;
        }
        if (stderr) {
            res.status(404).send(`${stderr}`);
            return;
        }
        res.status(200).send(`${stdout}`);
    });
})

app.delete('*', function(req, res) {
    var cmd = "/usr/bin/kv delete " + req.path;
    console.log(req.auth.user+":"+cmd);
    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            res.status(500).send(`${error.message}`);
            return;
        }
        if (stderr) {
            res.status(404).send(`${stderr}`)
            return;
        }
        res.status(202).send(`${stdout}`);
    });
})

app.post('*', jsonParser, function(req, res) {
    console.log(req.auth.user+":callback:" + req.body.kv);
    res.status(200).send();
})
