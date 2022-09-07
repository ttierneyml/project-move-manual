import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.TaskAction;
import java.net.*;
import java.util.*;
import java.io.*;
import java.nio.file.*;

public class DownloadZip extends DefaultTask {

    private String filePath = "";

    public void setFilePath(String s){
        filePath = s;
    }

    @TaskAction
    public void downloadZip(){
        URL url;
        byte[] array = new byte[120];
        try{
            url = new URL("http://data.gdeltproject.org/gdeltv2/lastupdate.txt");
            InputStream in = url.openStream();
            in.read(array);
            String data = new String(array);
            String[] dataSplit = data.split(" ");
            String dataUrl = dataSplit[2].substring(0, dataSplit[2].lastIndexOf("zip") + 3);
            in = new URL(dataUrl).openStream();
            Files.copy(in, Paths.get(filePath), StandardCopyOption.REPLACE_EXISTING);
        }
        catch(MalformedURLException ex){
            System.out.println("The url is not well formed");
        }
        catch(IOException ioException)
        {
            System.out.println("io exception");
        }
    }
}