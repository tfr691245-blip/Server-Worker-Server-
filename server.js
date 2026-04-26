// Simple server to keep the node alive
console.log("Server Started Successfully!");

// This keeps the process running every 1 minute
setInterval(() => {
    const memoryUsage = process.memoryUsage().rss / 1024 / 1024;
    console.log(`Server heartbeat. Memory usage: ${memoryUsage.toFixed(2)} MB`);
}, 60000);
