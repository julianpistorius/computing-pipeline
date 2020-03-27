# IRODS integration

Note: This is a work in progress

Related GitHub issue: [Ensure all captured data at ua-mac field site are delivered to UA #38](https://github.com/AgPipeline/computing-pipeline/issues/38)


## How data gets to UA from Gantry Cache Server

New crop data is automatically deposited here on the fieldscanner-data.arizona.edu host via Globus:

`/irods_vault/terraref-ds06/home/shared/terraref/ua-mac/raw_data/`

See this PR for details: <https://github.com/terraref/computing-pipeline/pull/592>


## How data gets tarred and ingested into CyVerse Data Store

See `tar-multiple-datasets.sh`.

For example to tar & ingest all the low-priority sensors from mid-Jan to early-March for season 10:

(Assuming that the scripts in the `irods-upload` folder has been copied to `irods_vault/.tmp/bin` on the fieldscanner-data.arizona.edu server.)
         
```bash
ssh -p 1657 root@fieldscanner-data.arizona.edu 

su - irods
cd /irods_vault/.tmp/bin/

seq -w 15 31 | xargs -L 1 -I % echo 2020-01-% > new_dates.txt
seq -w 01 29 | xargs -L 1 -I % echo 2020-02-% >> new_dates.txt
seq -w 01 03 | xargs -L 1 -I % echo 2020-03-% >> new_dates.txt
cat new_dates.txt | sort -r > dates.txt

./tar-multiple-datasets.sh season_10 /irods_vault/.tmp/bin/sensors-low-priority.txt /irods_vault/.tmp/bin/dates.txt
```

## TODO

(In rough order of priority)

- [ ] Deal with very large tar files
    - See <https://github.com/AgPipeline/issues-and-projects/issues/115>
- [ ] Make sure all the files on the gantry have been transferred to UA
- [ ] Schedule automated ingestion
- [ ] Check quality/correctness of tars
- [ ] Versioning of tars if new data for a day/sensor shows up
- [ ] Save md5 hashes of tar files in the TSV file
- [ ] Use workflow engine (`doit` or `makeflow`) for making tars instead of shell scripts
    - Will allow retries and make for more reliable operation

 
 