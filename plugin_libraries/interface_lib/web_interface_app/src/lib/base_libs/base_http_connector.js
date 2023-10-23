import { writable } from "svelte/store";
import {registered_connectors} from "../stores/base_http_connectors.js";
// THIS IS A STORE FOR ACTIVE CONNECTORS
export const BASE_CONNECTORS  = writable({});

export function get_connector(CONNECTOR_NAME)
{
    if(BASE_CONNECTORS[CONNECTOR_NAME] == undefined)
    {
        if(registered_connectors[CONNECTOR_NAME] != undefined)
        {
            let ADDRESS = registered_connectors[CONNECTOR_NAME].address;
            let PORT = registered_connectors[CONNECTOR_NAME].port;
            const NEW_CONNECTOR  = writable(start_connector(ADDRESS,PORT));

            console.log("Started Connector");
            BASE_CONNECTORS[CONNECTOR_NAME] = NEW_CONNECTOR;
            return NEW_CONNECTOR;
        }else
        {
            console.log("No Such Connector Registered");
            console.log(CONNECTOR_NAME);
            return "no_such_connector_available"
        }
       
    }else
    {
        console.log("Existing Connctor Sotre Found");
        return BASE_CONNECTORS[CONNECTOR_NAME];
    }

}

function start_connector(ADDRESS,PORT) 
{
    let NEW_BASE_CONNECTOR = 
    {
        connected: false,
        logged_in: false,
        port: PORT,
        socket_address: ADDRESS,
        USERNAME: null,
        SESSION_ID: null,
        USERBC: null,

        server_heartbeat: function () 
        {
            let HB = JSON.stringify({ context: "heartbeat", subject: "heartbeat", content: "heartbeat" });
            let Result = server_heartbeat(HB,this.socket_address, this.port);
            
            if (Result == "error") {
                this.connected = false;
                
            } else    
            if (Result.subject == "server_heartbeat") {
                
                    if (Result.content == "ok") {
                        this.connected = true;
                    } else {
                        this.connected = false;
                    }
            }

        },

        login: function (USERNAME, SESSION_PSWD) {
            let SESSION_LOGIN_MSG = JSON.stringify({ username: USERNAME, password: SESSION_PSWD });
            let RESULT = login_call(SESSION_LOGIN_MSG,this.socket_address, this.port);

            if (RESULT.subject == "login_failed") 
            {
                this.logged_in= false;
                this.USERNAME = USERNAME;
                return {error: RESULT.reason};

            } else if(RESULT.subject == "login_success") {
                
                this.logged_in = true;
                this.USERNAME = USERNAME;
                this.SESSION_ID = RESULT.user_session_id;
                this.USERBC = RESULT.user_bc;
                return "login_success";
            }else{
                return { login_failed:"unkown_error"}
            }
        },
        call: function (Msg) {
            Msg.user_session_id = this.SESSION_ID;
            let CALL = JSON.stringify(Msg);
            // console.log(CALL);
            let Result = call_(CALL,this.socket_address, this.port);
            return Result;

        }

    };
    heartbeat_latch(NEW_BASE_CONNECTOR);
    return NEW_BASE_CONNECTOR;
}


// An obfuscation of the REST call to the erlang http server
function call_(CALL_JSON, address, Port) {

    let QUERY_STR = "http://"+address+":" + Port + "/erl/http_connector_server_ep/call";
    let xmlHttpReq = new XMLHttpRequest();
    xmlHttpReq.open("POST", QUERY_STR,false);
    xmlHttpReq.send(CALL_JSON);
    let RESULT = xmlHttpReq.responseText;
    return JSON.parse(RESULT);
}

// An obfuscation of the REST call to the erlang http server
function cast_(CAST, address, Port) {

    let QUERY_STR = "http://"+address+":" + Port + "/erl/http_connector_server_ep/cast/MSG=" + encodeURI(CAST);
    let xmlHttpReq = new XMLHttpRequest();
    xmlHttpReq.open("GET", QUERY_STR, false);
    xmlHttpReq.send(null);
    return xmlHttpReq.responseText;
}

function login_call(SESSION_LOGIN_MSG,address, Port) {

    let QUERY_STR = "http://"+address+":" + Port + "/erl/http_connector_server_ep/login/MSG=" + encodeURI(SESSION_LOGIN_MSG);
    let xmlHttpReq = new XMLHttpRequest();
    xmlHttpReq.open("GET", QUERY_STR, false);
    try {
        xmlHttpReq.send(null);
    } catch (error) {
        console.error(error)
    };


    let RESULT = xmlHttpReq.responseText;
    return JSON.parse(RESULT);
}
function heartbeat_latch(CONNECTOR)
{
    CONNECTOR.server_heartbeat();
    setTimeout(()=> heartbeat_latch(CONNECTOR),5000);
}
function server_heartbeat(HB,address, Port) {
    try {
        let QUERY_STR = "http://"+address+":" + Port + "/erl/http_connector_server_ep/server_heartbeat/MSG=" + encodeURI(HB);
        let xmlHttpReq = new XMLHttpRequest();
        xmlHttpReq.open("GET", QUERY_STR, false);
        try {
            xmlHttpReq.send(null);
        } catch (error) {
            console.error(error);
            return "error"
        };
        let RESULT = xmlHttpReq.responseText;
        try {
            let Result = JSON.parse(RESULT);
            
            return Result;
        } catch (error) {
            console.error(error)
            return "error"
        };

    } catch (error) {
        return "error"
    }

}


