<!-- !/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
endregion -->

Project status
--------------

[![npm](https://img.shields.io/npm/v/containerbase?color=%23d55e5d&label=npm%20package%20version&logoColor=%23d55e5d)](https://www.npmjs.com/package/containerbase)
[![npm downloads](https://img.shields.io/npm/dy/containerbase.svg)](https://www.npmjs.com/package/containerbase)

[![<LABEL>](https://github.com/thaibault/containerbase/actions/workflows/build-image-periodically-1-branches.yaml/badge.svg)](https://github.com/thaibault/containerbase/actions/workflows/build-image-periodically-1-branches.yaml)
[![<LABEL>](https://github.com/thaibault/containerbase/actions/workflows/test.yaml/badge.svg)](https://github.com/thaibault/containerbase/actions/workflows/test.yaml)

[![documentation website](https://img.shields.io/website-up-down-green-red/https/torben.website/containerbase.svg?label=documentation-website)](https://torben.website/containerbase)

<!--|deDE:Einsatz-->
Use case
--------

A basic ArchLinux based docker configuration with configured and ready to use
git and yay.


Build locally
-------------
```
# Clone repo
gh repo clone jobrad-gmbh/tb-containerbase

# One of the following should work
docker buildx build --build-arg MULTI='' --no-cache --tag ghcr.io/jobrad-gmbh/tb-containerbase:latest
# ... or this
docker buildx build --build-arg MULTI='' --build-arg MIRROR_AREA_PATTERN='default' --no-cache --tag ghcr.io/jobrad-gmbh/tb-containerbase:latest --progress=plain .

# Publishing with
docker push ghcr.io/jobrad-gmbh/tb-containerbase:latest
```

The '--progress=plain' option allows to debug variables by adding lines like

```
CMD echo "Variable 'var' = '$var'
``` 
to the Dockerfile.





<!-- region modline
vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:
endregion -->
