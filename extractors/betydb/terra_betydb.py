#!/usr/bin/env python

from pyclowder.utils import CheckMessage
from pyclowder.files import download_metadata, upload_metadata
from terrautils.extractors import TerrarefExtractor, is_latest_file, load_json_file, \
    build_metadata, build_dataset_hierarchy
from terrautils.betydb import add_arguments, get_sites, get_sites_by_latlon, submit_traits, \
    get_site_boundaries
from terrautils.metadata import get_extractor_metadata, get_terraref_metadata


def add_local_arguments(parser):
    # add any additional arguments to parser
    add_arguments(parser)

class BetyDBUploader(TerrarefExtractor):
    def __init__(self):
        super(BetyDBUploader, self).__init__()

        add_local_arguments(self.parser)

        # parse command line and load default logging configuration
        self.setup(sensor='stereoTop_canopyCover')

        # assign other argumentse
        self.bety_url = self.args.bety_url
        self.bety_key = self.args.bety_key

    def check_message(self, connector, host, secret_key, resource, parameters):
        self.start_check(resource)

        if not resource['name'].endswith(".csv"):
            self.log_skip(resource,"%s is not a CSV file" % resource['name'])
            return CheckMessage.ignore

        md = download_metadata(connector, host, secret_key, resource['id'])
        if get_extractor_metadata(md, self.extractor_info['name']) and not self.overwrite:
            self.log_skip(resource,"metadata indicates it was already processed")
            return CheckMessage.ignore
        return CheckMessage.download

    def process_message(self, connector, host, secret_key, resource, parameters):
        self.start_message(resource)

        with open(resource['local_paths'][0], 'r') as inputcsv:
            inputlines = inputcsv.readlines()

        if len(inputlines) <= 1:
            # first check if there is data besides header line
            self.log_info(resource, "no trait lines found in CSV; skipping upload")
        else:
            # submit CSV to BETY
            self.log_info(resource, "found %s trait lines; submitting CSV to bety" % str(len(inputlines)-1))
            submit_traits(resource['local_paths'][0], betykey=self.bety_key)

            # Add metadata to original dataset indicating this was run
            self.log_info(resource, "updating file metadata (%s)" % resource['id'])
            ext_meta = build_metadata(host, self.extractor_info, resource['id'], {}, 'file')
            upload_metadata(connector, host, secret_key, resource['id'], ext_meta)

        self.end_message(resource)

if __name__ == "__main__":
    extractor = BetyDBUploader()
    extractor.start()
