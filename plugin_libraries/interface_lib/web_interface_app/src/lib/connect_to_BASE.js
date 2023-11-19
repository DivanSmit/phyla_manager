export async function get_data(Tag1, Tag2 = "INFO") {

    let MSG = {subject: "INFO", queryParam:Tag2, tag: Tag1};

    try {
        let url = new URL("http://localhost:9001/erl/http_session_gen_server/fetchdata");
        url.searchParams.append("MSG", JSON.stringify(MSG));
        const response = await fetch(url);
        if (response.ok) {
            const data = await response.json();
            return data.content;
        } else {
            console.error('Request failed:', response.status, response.statusText);
            return [];
        }
    } catch (error) {
        console.error('Error:', error);
        return [];
    }
}

export async function spawnInstance(Tag, Param) {

    let MSG = {subject: "SPAWN", queryParam:"SPAWN", tag: Tag, param: Param};

    try {
        let url = new URL("http://localhost:9001/erl/http_session_gen_server/fetchdata");
        url.searchParams.append("MSG", JSON.stringify(MSG));
        const response = await fetch(url);
        if (response.ok) {
            const data = await response.json();
            return data.content;
        } else {
            console.error('Request failed:', response.status, response.statusText);
            return [];
        }
    } catch (error) {
        console.error('Error:', error);
        return [];
    }
}

export async function userInteraction(User, Param, ID = '') {

    let MSG = {subject: "USERInteract", user: User, param: Param, tag: "TASKS", taskID: ID};

    try {
        let url = new URL("http://localhost:9001/erl/http_session_gen_server/fetchdata");
        url.searchParams.append("MSG", JSON.stringify(MSG));
        const response = await fetch(url);
        if (response.ok) {
            const data = await response.json();
            return data.content;
        } else {
            console.error('Request failed:', response.status, response.statusText);
            return [];
        }
    } catch (error) {
        console.error('Error:', error);
        return [];
    }
}

export async function getuserData(User, Param) {

    let MSG = {subject: "UserData", user: User, param: Param, tag: "INFO"};

    try {
        let url = new URL("http://localhost:9001/erl/http_session_gen_server/fetchdata");
        url.searchParams.append("MSG", JSON.stringify(MSG));
        const response = await fetch(url);
        if (response.ok) {
            const data = await response.json();
            return data.content;
        } else {
            console.error('Request failed:', response.status, response.statusText);
            return [];
        }
    } catch (error) {
        console.error('Error:', error);
        return [];
    }
}
