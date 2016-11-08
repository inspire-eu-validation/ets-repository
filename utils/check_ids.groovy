// Run with 'groovy check_ids.groovy' in utils directory
//
// Todos:
// - relations (parent,...)
//
//
// @author jonherrmann
import static groovy.io.FileType.FILES

def xmlSlurper = new XmlSlurper()

def idFileMap = [:]
def errMsgBuilder = ''<<''
def lineSep = System.getProperty("line.separator")

new File('../').eachFileRecurse(FILES) { file ->
    if(file.name.startsWith('ets-') && file.name.endsWith('-bsxets.xml')) {
        println "Parsing $file"
        def xml = xmlSlurper.parse(file);
        def ids = xml.'**'.findAll{ it.@id != "" }.'@id'
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
    System.exit(0)
}else{
    println "${lineSep}Results:"
    println errMsgBuilder
    System.exit(1)
}
