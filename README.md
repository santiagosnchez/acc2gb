# acc2gb_parallel
Shell code to retrieve GenBank records from a list of accession numbers (using [gnu-parallel](https://www.gnu.org/software/parallel/))

## NCBI API key

This program used to work well before NCBI's decision to implement an API key with restrictions on simultaneous request. As fo [May 1, 2018](https://ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities/) having an API key will grant you 10 requests per second, compared to 3 per second without an API key.

**Important Note:** I've adaped the code to allow the addition of a personal API key that will be saved system-wise. However, after multiple testing rounds, even after selecting `-threads 10` or lower, there are instances where an `exceeded the API key limit` error is thrown out causing an incomplete download. I'm currently reviewing ways to overcome this. **But for the time being, it is best to simply run the program single-threaded `-threads 1`.

## Requirements

1. Bash
~~2. [GNU-parallel](https://www.gnu.org/software/parallel/)~~

~~**GNU-parallel** needs to be installed and available on the system `PATH`.~~ This is no longer a requirement as the program can be run single-threaded. GNU-parallel is still a super useful to have installed in you computer anyway.




