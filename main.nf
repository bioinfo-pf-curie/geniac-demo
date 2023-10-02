#!/usr/bin/env nextflow

/*
Copyright Institut Curie 2020-2023
This software is a computer program whose purpose is to analyze high-throughput sequencing data.
You can use, modify and/ or redistribute the software under the terms of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful, but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
Users are therefore encouraged to test the software's suitability as regards their requirements in conditions enabling the security of their systems and/or data. 
The fact that you are presently reading this means that you have had knowledge of the license and that you accept its terms.
*/

/*
========================================================================================
                         @git_repo_name@
========================================================================================
 @git_repo_name@ analysis Pipeline.
 #### Homepage / Documentation
 @git_url@
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

// Initialize lintedParams and paramsWithUsage
NFTools.welcome(workflow, params)

// Use lintedParams as default params object
paramsWithUsage = NFTools.readParamsFromJsonSettings("${projectDir}/parameters.settings.json")
params.putAll(NFTools.lint(params, paramsWithUsage))

// Run name
customRunName = NFTools.checkRunName(workflow.runName, params.name)

/*
===================================
  SET UP CONFIGURATION VARIABLES
===================================
*/

// Genome-based variables
if (!params.genome){
  exit 1, "No genome provided. The --genome option is mandatory"
}

if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
  exit 1, "The provided genome '${params.genome}' is not available in the genomes file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
}

// Stage config files
multiqcConfigCh = Channel.fromPath(params.multiqcConfig)
outputDocsCh = file("$projectDir/docs/output.md", checkIfExists: true)

/*
==========================
 BUILD CHANNELS
==========================
*/

// Validate inputs
if ((params.reads && params.samplePlan) || (params.readPaths && params.samplePlan)){
  exit 1, "Input reads must be defined using either '--reads' or '--samplePlan' parameters. Please choose one way."
}

if ( params.metadata ){
  Channel
    .fromPath( params.metadata )
    .ifEmpty { exit 1, "Metadata file not found: ${params.metadata}" }
    .set { metadataCh }
}else{
  metadataCh = Channel.empty()
}

// Create a channel for input read files


/***************
 * Design file *
 ***************/

// UPDATE BASED ON YOUR DESIGN

if (params.design){
  Channel
    .fromPath(params.design)
    .ifEmpty { exit 1, "Design file not found: ${params.design}" }
    .set { designCheckCh }

  designCh = designCheckCh 

  designCh
    .splitCsv(header:true)
    .map { row ->
      if(row.AGE==""){row.AGE='NA'}
      return [ row.SAMPLE_ID, row.AGE, row.TYPE ]
     }
    .set { designCh }
}else{
  designCheckCh = Channel.empty()
  designCh = Channel.empty()
}


/*
===========================
   SUMMARY
===========================
*/

summary = [
  'Pipeline' : workflow.manifest.name ?: null,
  'Version': workflow.manifest.version ?: null,
  'DOI': workflow.manifest.doi ?: null,
  'Run Name': customRunName,
  'Inputs' : params.samplePlan ?: params.reads ?: null,
  'Genome' : params.genome,
  'Max Resources': "${params.maxMemory} memory, ${params.maxCpus} cpus, ${params.maxTime} time per job",
  'Container': workflow.containerEngine && workflow.container ? "${workflow.containerEngine} - ${workflow.container}" : null,
  'Profile' : workflow.profile,
  'OutDir' : params.outDir,
  'WorkDir': workflow.workDir,
  'CommandLine': workflow.commandLine
].findAll{ it.value != null }

workflowSummaryCh = NFTools.summarize(summary, workflow, params)

/*
==============================
  LOAD INPUT DATA
==============================
*/

// Load raw reads
rawReadsCh = NFTools.getInputData(params.samplePlan, params.reads, params.readPaths, params.singleEnd, params)

// Make samplePlan if not available
sPlanCh = NFTools.getSamplePlan(params.samplePlan, params.reads, params.readPaths, params.singleEnd)

/*
==================================
           INCLUDE
==================================
*/ 

// ADD YOUR NEXTFLOW SUBWORFLOWS HERE
// Workflows
// QC : check design and factqc
include { myWorkflow0 } from './nf-modules/local/subworkflow/myWorkflow0'
include { myWorkflow1 } from './nf-modules/local/subworkflow/myWorkflow1'

// Processes
include { getSoftwareVersions } from './nf-modules/local/process/getSoftwareVersions'
include { workflowSummaryMqc } from './nf-modules/local/process/workflowSummaryMqc'
include { multiqc } from './nf-modules/local/process/multiqc'
include { glad } from './nf-modules/local/process/glad'
include { renvInit as renvGladInit } from './nf-modules/local/process/renvInit'
include { outputDocumentation } from './nf-modules/local/process/outputDocumentation'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow {
    main:

     // myWorkflow0
     myWorkflow0(
       designCheckCh,
       sPlanCh,
       rawReadsCh
     )

     /*****************************************************************************************
      * workflow example with the following processes:                                        *
      *  - with local variable                                                                *
      *  - helloWorld from source code                                                         *
      *  - process with onlyLinux (standard unix command)                                     *
      *  - process with onlylinux (invoke script from bin/ directory)                         *
      *  - some process with a software that has to be installed with a custom conda yml file *
      *****************************************************************************************/
     // myWorkflow1
     oneToFiveCh = Channel.of(1..5)
     myWorkflow1(
       oneToFiveCh
     )

     /***************************
      * Example with R and renv *
      ***************************/
	  renvGladInit('renvGlad')
      glad(renvGladInit.out.renvInitDone)

     /*********************
      * Software versions *
      *********************/
     getSoftwareVersions(
       myWorkflow0.out.version.first().ifEmpty([])
     )

     /********************
      * Workflow summary *
      ********************/
     workflowSummaryMqc(summary) 

     /***********
      * MultiQC *
      ***********/
     multiqc(
       customRunName,
       sPlanCh.collect(),
       multiqcConfigCh,
       myWorkflow0.out.fastqcResultsCh.collect().ifEmpty([]),
       metadataCh.ifEmpty([]),
       getSoftwareVersions.out.collect().ifEmpty([]),
       workflowSummaryMqc.out.collect()
     )
     mqcReport = multiqc.out.report.toList()

     /****************
      * Sub-routines *
      ****************/
     outputDocumentation(outputDocsCh)
}

workflow.onComplete {
  NFTools.makeReports(workflow, params, summary, customRunName, mqcReport)
}
