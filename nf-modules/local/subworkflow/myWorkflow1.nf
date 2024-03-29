/*
Copyright Institut Curie 2020-2023

This software is a computer program whose purpose is to
provide a demo with geniac.
You can use, modify and/ or redistribute the software under the terms
of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful,
but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
Users are therefore encouraged to test the software's suitability as regards
their requirements in conditions enabling the security of their systems and/or data.
The fact that you are presently reading this means that you have had knowledge
of the license and that you accept its terms.

*/

/*****************************************************************************************
 * workflow example with the following processes:                                        *
 *  - with local variable                                                                *
 *  - helloWorld from source code                                                         *
 *  - process with onlyLinux (standard unix command)                                     *
 *  - process with onlylinux (invoke script from bin/ directory)                         *
 *  - some process with a software that has to be installed with a custom conda yml file *
 *****************************************************************************************/

// include required processes
include { alpine } from '../process/alpine'
include { helloWorld } from '../process/helloWorld'
include { standardUnixCommand } from '../process/standardUnixCommand'
include { execBinScript } from '../process/execBinScript'
include { trickySoftware } from '../process/trickySoftware'

workflow myWorkflow1 {
    // required inputs
    take:
      oneToFiveCh
      
    // workflow implementation
    main:
      alpine(oneToFiveCh)
      helloWorld()
      standardUnixCommand(helloWorld.out)
      execBinScript()
}
