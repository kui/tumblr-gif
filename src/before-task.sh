#!/bin/bash

set_x

load_rc

avconv -version &>/dev/null || avconv

convert -version &>/dev/null || convert
