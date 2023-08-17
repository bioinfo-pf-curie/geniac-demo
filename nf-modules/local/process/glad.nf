
process glad {
  label 'renvGlad'
  label 'minCpu'
  label 'minMem'
  publishDir "${params.outDir}/GLAD", mode: 'copy'

  input:
  val renvInitDone

  output: 
  file "BkpInfo.tsv"

  script:
  """
  Rscript ${projectDir}/bin/apGlad.R
  """
}
