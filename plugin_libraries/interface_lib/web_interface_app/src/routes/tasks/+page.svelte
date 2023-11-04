<script>
    import {onMount} from "svelte";
    import { get_data } from "$lib/connect_to_BASE.js";
    import {moveFruitTask} from "$lib/connect_to_BASE.js";
    import { getMeasurements } from "$lib/connect_to_BASE.js";

    let operatorData = [];
    let measureData = [];
    let isDatarecieved = false;

    const startTask = async () => {
        operatorData = await moveFruitTask();
        isDataLoaded = false;
    };

    const startMeasure = async() => {
        measureData = await getMeasurements();
        isDatarecieved = false;
    };

    onMount(() => {
        setInterval(async()=>{
            if(isDatarecieved){
                measureData = await get_data("MEASURE_FTA_VALUES");
                console.log("Data: ",measureData);
            }
                }, 2000);
    });

</script>

<style>
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

    .start-button {
        background-color: yellow;
        color: #000;
    }

    .start-button-container {
        display: flex;
        justify-content: center;
        align-items: center;
        margin-top: 20px;
    }
</style>

<div class="start-button-container">
    <a href="#" class="button start-button" on:click={startTask}>Move Fruit</a>
    <a href="#" class="button start-button" on:click={startMeasure}>Start Measurement</a>
    <a href="#" class="button start-button" on:click={()=>isDatarecieved=false}>Cancel</a>
</div>
<!-- 
<ul>
    {#each measureData.content as item (item)}
      <li>{item[0]}</li>
    {/each}
  </ul> -->