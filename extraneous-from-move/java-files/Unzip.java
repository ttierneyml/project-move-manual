import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.TaskAction;
import java.io.*;

public class Unzip extends DefaultTask {
    
    @TaskAction
    public void unzip(){
        try{
            Process process = Runtime.getRuntime().exec("/Users/ttierney/Code/project-move/unzip.sh");
        }
        catch(IOException ioException)
        {
            System.out.println("io exception");
        }
    }
}