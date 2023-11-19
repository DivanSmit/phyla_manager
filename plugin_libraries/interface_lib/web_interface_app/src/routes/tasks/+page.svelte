<script>
// @ts-nocheck
    import { onMount } from 'svelte';
    import {spawnInstance} from "$lib/connect_to_BASE.js";

    let isDatarecieved = true;
    let selectedDate = '';
    let selectedTime = '';
    let unixTimestamp = null;

    let timeOptions = generateTimeOptions();

    let fseSpawnTag = "SPAWN_FSE_INSTANCE";
    let ftaMeasureSpawnTag = "";
    let moveFruitSpawnTag = "SPAWN_MOVE_FRUIT_INSTANCE";

    async function spawnTaskRequest(tag1 = "", tag2 = ""){
        let response = await spawnInstance(tag1, tag2);
        isDatarecieved = true;
    }
    
    function generateTimeOptions() {
      const options = [];
      for (let hour = 0; hour < 24; hour++) {
        for (let minute = 0; minute < 60; minute += 15) {
          const formattedHour = hour.toString().padStart(2, '0');
          const formattedMinute = minute.toString().padStart(2, '0');
          options.push(`${formattedHour}:${formattedMinute}`);
        }
      }
      return options;
    }

    function calculateUnixTimestamp() {
        const selectedDateTime = new Date(`${selectedDate}T${selectedTime}`);
        unixTimestamp = selectedDateTime.getTime(); // Convert milliseconds to seconds
        console.log(unixTimestamp);
    }

    onMount(() => {
        // Your code to run after the component is mounted
        isDatarecieved = true;
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

    .start-container {
        display: flex;
        justify-content: center;
        align-items: center;
        margin-top: 20px;
    }
</style>

<div class="start-container">
    <a href="#" class="button start-button" on:click={() =>spawnTaskRequest(moveFruitSpawnTag)}>Move Fruit</a>
    <a href="#" class="button start-button" on:click={() =>spawnTaskRequest(fseSpawnTag, unixTimestamp)}>Start FSE</a>
</div>
<div class="start-container">
    <h1 class="header">Select Date and Time</h1>
    <div class="input-container">
        <label for="date">Date:</label>
        <input type="date" id="date" bind:value={selectedDate} />
    </div>
    <div class="input-container">
        <label for="time">Time:</label>
        <select id="time" bind:value={selectedTime}>
            {#each timeOptions as timeOption}
            <option value={timeOption}>{timeOption}</option>
            {/each}
        </select>
    </div>
    <div class="selected-info">
        <p>Selected Date: {selectedDate}</p>
        <p>Selected Time: {selectedTime}</p>
    </div>
    <button on:click={() => calculateUnixTimestamp()}>Start</button>
</div>

<!-- 
<ul>
    {#each measureData.content as item (item)}
      <li>{item[0]}</li>
    {/each}
  </ul> -->

  <!-- <a href="#" class="button start-button" on:click={spawnTaskRequest}>Start Measurement</a> -->
    <!-- <a href="#" class="button start-button" o>Cancel</a> -->
