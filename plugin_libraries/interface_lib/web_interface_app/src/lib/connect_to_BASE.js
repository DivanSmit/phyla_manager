export async function get_data(Tag) {

    let MSG = { queryParam:"INFO", tag: Tag};

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

export async function addOperator(Name) {


    var randomNumber = Math.floor(Math.random() * 1000);
    let MSG = { queryParam:"SPAWN", tag: "SPAWN_OPERATOR_INSTANCE", name: Name};

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

export async function moveFruitTask() {

    var randomNumber = Math.floor(Math.random() * 1000);
    let MSG = { queryParam:"SPAWN", tag: "SPAWN_MOVE_FRUIT_INSTANCE",name:"MoveFruit"+randomNumber};

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

export async function getMeasurements() {

    var randomNumber = Math.floor(Math.random() * 1000);
    let MSG = { queryParam:"SPAWN", tag: "SPAWN_FTA_MACHINE_INSTANCE",name:"fta_machine_"+randomNumber};

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
