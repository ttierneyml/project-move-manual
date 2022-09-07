import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.TaskAction;
import java.io.*;

public class APIImport extends DefaultTask {
    
    @TaskAction
    public void APIImport(){
        try{
            Process process = Runtime.getRuntime().exec("/Users/ttierney/Code/project-move/mlcpCall.sh");
        }
        catch(IOException ioException)
        {
            System.out.println("io exception");
        }
    }
}