export async function get_data() {

    let MSG = { queryParam:"type", tag:"OPERATOR_INSTANCE_INFO"};

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

export async function addOperator() {


    var randomNumber = Math.floor(Math.random() * 1000);
    let MSG = { queryParam:"addOperator", tag:"Operator"+randomNumber};

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