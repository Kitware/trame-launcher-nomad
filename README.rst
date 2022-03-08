=====================
Trame Launcher Nomad
=====================

Launcher service for `trame application <https://kitware.github.io/trame/>`_ when deployed within a Nomad managed cluster.
This code base can be use as-is or as a reference for building your own implementation.

`Nomad <https://www.nomadproject.io/>`_ is a simple and felxible scheduler and workload orchestrator to deploy and manage applications execution across on-prem and clouds at scale.

This project will offer a docker image to streamline scaling with Nomad on-prem or in the cloud. Additional documentation will be provided on how to setup your environment to manage your trame applications at scale.
In the meantime, you can `reach out <https://www.kitware.com/contact/>`_ so we can help you out.

* Free software: BSD License

License
--------

**trame-launcher-nomad** is distributed under the OSI-approved BSD 3-clause License.


Usage demonstrator
-------------------

For this example we suppose that Nomad and Consul are running.

```
cd ./nomad/jobs
nomad job run fabio.nomad
nomad job run trame-demo.nomad
nomad job run trame-launcher.nomad
```

Then you should be able to connect to `http://localhost:9999/index.html`

You should see a rudimentary form that let you dispatch a new job by its name.
Once submited, the page should redirect to connect you directly to the demo trame application.

The `trame-launcher-nomad` provide a `POST /launcher` endpoint that has the responsibilty to
dispatch a new job and provide informations on how to connect back to that running service.

The website is just issuing a POST request and if a redirect url is provided switch back to it.
