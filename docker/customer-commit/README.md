# Purpose
Show how customers would add "intrinsic" artifacts to DataPower within
an automated process driven by version control artifacts.

___
Examples of DataPower artifacts include keys and certs in cert:
or sharedcert:, users and passwords, and the like. These are things
that we do not want to appear in the clear in the Docker image, so
we avoid that by ensuring that they are placed directly into
DataPower, which persists them in the encrypted datapower.img
file, which is inside the image/container.

Note that at mastering time, the artifacts to have to appear "in the
clear".  The assumption is that this only happens on trusted, well-controlled environments where that is a safe assumption.

Otherwise, the same actions shown here could be done manually,
with all the caveats that manual steps bring.
