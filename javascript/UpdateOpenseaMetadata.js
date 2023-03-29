// Function to update OpenSea metadata for all JBProject tokens
async function fetchData(tokenId) {
    const url = `https://api.opensea.io/api/v1/asset/0xd8b4359143eda5b2d763e127ed27c77addbc47d3/${tokenId}/?force_update=true`;
  
    try {
      const response = await fetch(url);
      
      if (response.ok) {
        const data = await response.json();
        console.log(`Data for token ID ${tokenId}:`, data);
      } else {
        console.error(`Error fetching data for token ID ${tokenId}:`, response.statusText);
      }
    } catch (error) {
      console.error(`Error fetching data for token ID ${tokenId}:`, error);
    }
  }
  
  // Loop through the token IDs from 1 to 472 and make a GET request for each
  async function fetchAllData() {
    const startTokenId = 1;
    const endTokenId = 472;
  
    for (let tokenId = startTokenId; tokenId <= endTokenId; tokenId++) {
      await fetchData(tokenId);
    }
  }
  
  // Call the fetchAllData function
  fetchAllData();  