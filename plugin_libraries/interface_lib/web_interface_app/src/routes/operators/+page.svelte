<script>
// @ts-nocheck

    import {onMount} from "svelte";
    import {spawnInstance} from "$lib/connect_to_BASE.js";
    import { get_data } from "$lib/connect_to_BASE.js";
    
    let isInputVisible = false;
    let response = [];
    let inputData = "";

    let operatorSpawnTag = "SPAWN_OPERATOR_INSTANCE";
    let operatorInfoTag = "OPERATOR_INSTANCE_INFO";
    let machineInfoTag = "FTA_INSTANCE_INFO";
    let machineSpawnTag = "SPAWN_FTA_MACHINE_INSTANCE";

    let listOfTags= [operatorInfoTag,machineInfoTag];
    let listOfData = [];
    let operatorData = [];
    let machineData = [];

    function showInput(){
        if(isInputVisible){
            isInputVisible = false;
        }else{
            isInputVisible = true;
        }
    }

    async function spawnInstanceRequest(tag1 = "", tag2 = "nothing"){
        isInputVisible =false;
        response = await spawnInstance(tag1,tag2);
    }

    async function fetchData(){
        let len = listOfTags.length;
        listOfData = [];

        for (let i = 0; i < len; i++) {
            const currentItem = listOfTags[i];
            const responseList = await get_data(currentItem);
            listOfData.push(responseList);
        }

        operatorData = listOfData[0];
        machineData = listOfData[1];
    }

    onMount(()=>{
        fetchData();
    })

</script>

<style>
    /* body {
        font-family: Arial, sans-serif;
        background-color: #f0faff;
        text-align: center;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
    } */

    .button-container {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        align-items: center;
        gap: 20px;
    }

    .button {
        display: inline-block;
        padding: 15px 30px;
        margin: 10px;
        background-color: #4CAF50;
        color: #fff;
        border: 2px solid #000;
        border-radius: 50px;
        cursor: pointer;
        font-size: 18px;
        text-decoration: none;
        transition: background-color 0.3s, transform 0.3s, box-shadow 0.3s;
        box-shadow: 0 6px 12px rgba(0, 0, 0, 0.2);
    }

    .button:hover {
        transform: scale(1.25);
        box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
    }

    footer {
        color: #000;
        padding: 10px 0;
        text-align: center;
    }
    .mainText{
        text-align: center;
        margin-top: 10px;
        margin-bottom: 20px;
        font-size: 30px;
    }

    .operator-container {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        align-items: center;
        gap: 20px;
    }

    .section {
        flex: 1;
        text-align: center;
        background-color: #f0f0f0;
        border: 1px solid #ccc;
        padding: 20px;
        margin: 10px;
        border-radius: 8px;
        box-shadow: 0 0 8px rgba(0, 0, 0, 0.2);
    }

    .section:hover {
        background-color: #e0e0e0;
    }

    .data-block {
        background-color: #f0f0f0;
        border: 1px solid #ccc;
        padding: 10px;
        margin: 10px;
        border-radius: 5px;
        width: 100%;
    }
    .data-container {
        display: flex;
        flex-direction: column;
        align-items: center;

    }

    .two-column-layout {
        display: flex;
    }

    .column {
        flex: 1;
        padding: 10px;
        border: 3px solid #000;
        margin: 10px;
        border-radius: 5px;
        align-items: center;
        flex-wrap: wrap;
        justify-content: center;
        align-items: center;
    }

    .data-column {
        flex: 4; /* Data column takes twice the width of the second column */
    }

    .container {
        text-align: center;
    }

    .header {
        background-color: #333;
        color: #fff;
        padding: 10px;
    }

    .column-blocks{
        display: flex;
        flex-direction: column;
        padding: 10px;
    }
    .block {
        background-color: #f0f0f0;
        border: 1px solid #ccc;
        padding: 20px;
        flex: 1; /* Each block takes an equal portion of the row */
        margin-right: 10px;
        text-align: center;
        widows: 100%;
    }

</style>

<div class="two-column-layout">
    <div class="column">
        <div class="container">

            <a href="#" class="button" on:click={fetchData}>Refresh</a>
            <div class="header">
                <h1>Operators</h1>
            </div>

            <div class="column-blocks">
                <div class="operator-container">

                    {#if operatorData.length > 0}
                        <div class="data-container">
                            {#each operatorData as item}
                                <div class="block">
                                    <p>{item.name}</p>
                                </div>
                            {/each}
                        </div>
                    {:else}
                        <p>No data available.</p>
                    {/if}
                </div>
            </div>
        </div>
        <div class="container">
            <div class="header">
                <h1>Machines</h1>
            </div>

            <div class="column-blocks">
                <div class="operator-container">

                    {#if operatorData.length > 0}
                        <div class="data-container">
                            {#each machineData as item}
                                <div class="block">
                                    <p>{item.name}</p>
                                </div>
                            {/each}
                        </div>
                    {:else}
                        <p>No data available.</p>
                    {/if}
                </div>
            </div>
        </div>
    </div>
    <div class="column data-column">
        <p class="mainText">Click on a button below:</p>
        <div class="button-container">
            <a href="#" class="button" on:click={showInput}>Add Operator</a>
            <a href="#" class="button" on:click={() => spawnInstanceRequest(machineSpawnTag)}>Add Machine</a>
            <a href="#" class="button" >Add Room</a>
            <a href="#" class="button" >Add Measurement</a>
        </div>
        
        <div class="button-container">
            {#if isInputVisible}
                <div>
                    Enter the name of the operator
                </div>
                Name: 
                <input type="text" bind:value={inputData} placeholder="Enter data" />
                <a href="#" class="button" on:click={spawnInstanceRequest(operatorSpawnTag,inputData)}>Save</a>
                <a href="#" class="button" on:click={showInput}>Cancel</a>

            {/if}
        </div>
    </div>
</div>



<footer>
    <p>&copy; 2023 Divan</p>
</footer>
