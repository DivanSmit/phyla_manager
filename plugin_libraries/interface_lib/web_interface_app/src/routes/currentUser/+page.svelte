<!-- ListElements.svelte -->
<script>
    import {onMount} from "svelte";
    import { getuserData } from "$lib/connect_to_BASE.js";
    import { userInteraction} from "$lib/connect_to_BASE.js";

    let username = '';
    let password = '';
    let ifLogedIn = false;
    let taskStatus = [];
    let taskData = [''];
    let taskIDs = [''];
    let taskTime = [''];

    function handleSubmit() {
        // You can implement the login logic here
        if (password === '') {
            ifLogedIn = true;
            getTaskData();
        } else {
            alert('Login failed');
        }
    }

    const handleTask = async (index = 0, state = "StartTask") => {
        taskStatus = await userInteraction(username,state,taskIDs[index]);
    };

    const getTaskData = async ()=>{
        taskData = await getuserData(username,"TASKSID");
        console.log(taskData)
        taskIDs = taskData[0].id;
        taskTime = taskData[0].time;
    }

</script>

<style>

    .container {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        height: 100vh;
    }

    .form {
        background-color: #30b635;
        border: 1px;
        border-color: #000;
        border-radius: 8px;
        padding: 20px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
        text-align: center;
    }

    .input {
        width: 100%;
        padding: 10px;
        margin: 10px 0;
        border: 1px solid #ccc;
        border-radius: 4px;
    }

    .button-login {
        background-color: #007BFF;
        color: #fff;
        padding: 10px 20px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
    }

    .element-list {
        display: flex;
        flex-direction: column;
    }

    .element-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 10px;
        border: 1px solid #ccc;
        margin: 10px 0;
    }

    .info {
        flex: 1;
    }

    .buttons {
        display: flex;
    }

    button {
        padding: 5px 10px;
        background-color: #007BFF;
        color: #fff;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        margin-right: 10px;
    }

    button:last-child {
        margin-right: 0;
    }

    button:hover {
        background-color: #0056b3;
    }

</style>


{#if !ifLogedIn}
    <div class="container">
        <div class="form">
        <h2>Login</h2>
        <input class="input" type="text" placeholder="Username" bind:value={username} />
        <!-- <input class="input" type="password" placeholder="Password" bind:value={password} /> -->
        <button class="button-login" on:click={handleSubmit}>Login</button>
        </div>
    </div>
{:else}
    <h2>Welcome {username}</h2>
    <div class="element-list">

        {#if taskTime[0] == ''}
            <div class="element-row">No Tasks</div>
        {:else}
            {#each taskTime as item, index (item)}
                <div class="element-row">
                    <div class="info">{item}</div>
                    <div class="buttons">
                        <button on:click={() => handleTask(index, "StartTask")}>Start Task</button>
                        <button on:click={() => handleTask(index, "EndTask")}>End Task</button>
                    </div>
                </div>
            {/each}
        {/if}

        
    </div>
{/if}


