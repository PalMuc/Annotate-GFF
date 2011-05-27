#!/bin/sh

ruby_version=$(ruby -v)
dir=$(dirname $0)
if [[ $ruby_version == jruby* ]];
then
    ruby "-J-Xmx2g" "${dir}/../lib/annotate-gff.rb" $*
else
    ruby "${dir}/../lib/annotate-gff.rb" $*
fi
