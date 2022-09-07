import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.TaskAction;
import java.io.*;

public class AddHeader extends DefaultTask {
    
    @TaskAction
    public void AddHeader(){
        try{
            Process process = Runtime.getRuntime().exec("/Users/ttierney/Code/project-move/addHeader.sh");
        }
        catch(IOException ioException)
        {
            System.out.println("io exception");
        }
    }
}
