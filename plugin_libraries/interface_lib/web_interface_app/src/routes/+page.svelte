
<!-- FancyDatePicker.svelte -->
<script>
    let selectedDate = '2023-11-10';
    let selectedTime = '00:00';
    let unixTimestamp = null;

    let timeOptions = generateTimeOptions();
    
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
        unixTimestamp = selectedDateTime.getTime() / 1000; // Convert milliseconds to seconds
        console.log(unixTimestamp);
    }
  </script>
  
  <main>
    <h1 class="header">Select Date and Time : </h1>
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

  </main>

  <style>
    .header {
      text-align: center;
      font-size: 24px;
      margin-bottom: 20px;
    }
  
    .input-container {
      display: flex;
      align-items: center;
      margin-bottom: 20px;
    }
  
    label {
      flex: 1;
      font-weight: bold;
    }
  
    input {
      flex: 2;
      padding: 10px;
      border: 1px solid #ccc;
      border-radius: 5px;
    }
  
    .selected-info {
      text-align: center;
      margin-top: 20px;
    }
  </style>
  