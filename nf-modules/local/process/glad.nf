
process glad {
  label 'renvGlad'
  label 'minCpu'
  label 'lowMem'
  publishDir "${params.outDir}/GLAD", mode: 'copy'

  input:
  val renvInitDone

  output: 
  path "BkpInfo.tsv"

  script:
  """
  Rscript ${projectDir}/bin/apGlad.R
  """
}
