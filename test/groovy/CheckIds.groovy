import groovy.util.GroovyTestCase
import static groovy.io.FileType.FILES

class CheckIds extends GroovyTestCase {

  def replaceUuidInFile(filename, sourceFile, uuid){

    final String prefix = './replacement-'

    final File source
    File dest = new File( prefix + filename )
    boolean tmp = false
    if(dest.exists()) {
      source = new File( prefix + filename )
      dest =  new File( prefix + filename + ".tmp" )
      tmp = true
    }else{
      source = sourceFile
    }
    dest.withWriter { w ->
      source.eachLine { line ->
        w << line.replaceAll( uuid, java.util.UUID.randomUUID().toString() ) + System.getProperty("line.separator")
      }
    }
    if(tmp) {
      final File sr = new File( prefix + filename )
      sr.delete();
      new File( prefix + filename + ".tmp" ).renameTo(sr)
    }
  }

  void testUniqueId() {

    def xmlSlurper = new XmlSlurper()

    def idFileMap = [:]
    def errMsgBuilder = ''<<''
    def lineSep = System.getProperty("line.separator")

    new File('./').eachFileRecurse(FILES) { file ->
        if(
          ((file.name.startsWith('ets-') && file.name.endsWith('-bsxets.xml')) ||
          file.name.endsWith('-soapui-project.xml')) && !file.name.startsWith('replacement-')) {
            println "Parsing $file"
            def xml = xmlSlurper.parse(file);
            def ids = xml.'**'.findAll{
              it.@id != "" && !it.@id.text().startsWith("com.eviware") && !it.@id.text().startsWith("ProjectSettings")
            }.'@id'
            ids.each { i ->
                // gpath attribute cast required
                String id = i
                println "Checking $id"
                def duplicateCheck = idFileMap[id]
                if(duplicateCheck!=null) {
                    if(duplicateCheck==file) {
                      def errMesg = "Non-unique ID ${id} found multiple times in ${file}"
                      println errMesg
                      errMsgBuilder <<= errMesg + lineSep
                      replaceUuidInFile(file.name, file, id)
                    }else{
                      def errMesg = "Non-unique ID ${id} found in ${file} which is also used in ${duplicateCheck}"
                      println errMesg
                      errMsgBuilder <<= errMesg + lineSep
                    }
                }else{
                    idFileMap.put(id,file)
                }
            }
        }
    }

    if(errMsgBuilder.toString().trim().equals("")) {
        println "${lineSep}OK"
    }else{
        println "${lineSep}Results:"
        println errMsgBuilder
    }
    assertEquals("", errMsgBuilder.toString().trim())
  }
}
