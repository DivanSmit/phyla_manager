<nav>
    <h1>Hortgro Operation Interface</h1>
    <ul>
        <li>
            <a href="/">Home</a>
        </li>
        <li>
            <a href="/operators">Resources</a>
        </li>
        <li>
            <a href="/tasks">Tasks</a>
        </li>
        <li>
            <a href="/currentUser">User</a>
        </li>

    </ul>
</nav>

<style>
    nav{
        display: flex;
        background-color: #4CAF50;
        color: black;
        transition: transform 0.2s, font-size 0.2s;
    }
    nav:hover {
    transform: translateY(5px); /* Drop down by 5 pixels on hover */
    font-size: 1.1em; /* Increase the font size */
  }

    ul {
        display: flex;
        margin: 0;
        margin-left: auto;
        list-style: none;
    }
    li{
        margin-right: 20px;
    }
    h1{
        margin: 0;
        font-size: 1.5em;
        font-weight: normal;

    }
    a{
        text-decoration: none;
        color: black;
    }
</style>
<slot/>